// Command step4 adds a control group, so the container cannot use more than
// a fixed number of processes or a fixed amount of memory.
//
// Usage: step4 run [-pids N] [-memory-mb N] <rootfs> <command> [args...]
package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

const cgroupRoot = "/sys/fs/cgroup"

func main() {
	if len(os.Args) < 2 {
		usage()
	}
	switch os.Args[1] {
	case "run":
		fs := flag.NewFlagSet("run", flag.ExitOnError)
		pids := fs.Int("pids", 20, "most processes the container may run")
		memMB := fs.Int("memory-mb", 100, "most memory the container may use, in MiB")
		fs.Parse(os.Args[2:])
		if fs.NArg() < 2 {
			usage()
		}
		run(fs.Arg(0), fs.Args()[1:], *pids, *memMB)
	case "child":
		child(os.Args[2], os.Args[3:])
	default:
		usage()
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: step4 run [-pids N] [-memory-mb N] <rootfs> <command> [args...]")
	os.Exit(2)
}

func run(rootfs string, args []string, pids, memMB int) {
	fmt.Printf("parent: pid %d, starting %v\n", os.Getpid(), args)

	// New: create the cgroup and set its limits before the child starts.
	cg, err := newCgroup(fmt.Sprintf("hmlk8s-%d", os.Getpid()), pids, memMB)
	must(err)
	defer cg.remove()

	cmd := exec.Command("/proc/self/exe", append([]string{"child", rootfs}, args...)...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.Env = append(os.Environ(), "HMLK8S_CGROUP_PROCS="+cg.procsFiles())
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Cloneflags: syscall.CLONE_NEWUTS | syscall.CLONE_NEWPID | syscall.CLONE_NEWNS,
	}
	err = cmd.Run()
	cg.remove() // os.Exit below skips deferred calls
	exitWith(err)
}

func child(rootfs string, args []string) {
	fmt.Printf("child:  pid %d, running %v\n", os.Getpid(), args)
	must(syscall.Sethostname([]byte("container")))

	// New: join the cgroup. Writing "0" to cgroup.procs moves the writer
	// itself. Everything it starts from now on inherits the limits.
	for _, f := range filepath.SplitList(os.Getenv("HMLK8S_CGROUP_PROCS")) {
		must(os.WriteFile(f, []byte("0"), 0o644))
	}

	must(syscall.Mount("", "/", "", syscall.MS_PRIVATE|syscall.MS_REC, ""))
	must(syscall.Chroot(rootfs))
	must(os.Chdir("/"))
	must(syscall.Mount("proc", "/proc", "proc", 0, ""))
	must(mountDev())

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.Env = []string{"PATH=/bin:/usr/bin:/sbin:/usr/sbin", "HOME=/root"}
	exitWith(cmd.Run())
}

// cgroup is one control group. On cgroup v2 hosts it is one directory. On
// older cgroup v1 hosts each controller has its own tree, so it is two.
type cgroup struct{ dirs []string }

func newCgroup(name string, pids, memMB int) (*cgroup, error) {
	mem := strconv.Itoa(memMB * 1024 * 1024)
	if _, err := os.Stat(filepath.Join(cgroupRoot, "cgroup.controllers")); err == nil {
		// cgroup v2: one directory holds every limit.
		dir := filepath.Join(cgroupRoot, name)
		if err := os.Mkdir(dir, 0o755); err != nil {
			return nil, err
		}
		cg := &cgroup{dirs: []string{dir}}
		if _, err := os.Stat(filepath.Join(dir, "pids.max")); errors.Is(err, os.ErrNotExist) {
			cg.remove()
			return nil, errors.New("pids and memory controllers are not enabled in " +
				cgroupRoot + "/cgroup.subtree_control; run this inside a kind node")
		}
		return cg, cg.write([][2]string{
			{"pids.max", strconv.Itoa(pids)},
			{"memory.max", mem},
			{"memory.swap.max", "0"},
		})
	}
	// cgroup v1: one directory per controller.
	cg := &cgroup{dirs: []string{
		filepath.Join(cgroupRoot, "pids", name),
		filepath.Join(cgroupRoot, "memory", name),
	}}
	for _, d := range cg.dirs {
		if err := os.Mkdir(d, 0o755); err != nil {
			cg.remove()
			return nil, err
		}
	}
	return cg, cg.write([][2]string{
		{"pids/" + name + "/pids.max", strconv.Itoa(pids)},
		{"memory/" + name + "/memory.limit_in_bytes", mem},
		{"memory/" + name + "/memory.memsw.limit_in_bytes", mem},
	})
}

// write sets each limit, in order. Each pair is a file name (v2) or a path
// under the cgroup root (v1), then its value. A missing optional file, such
// as swap accounting on a host that turns it off, is skipped.
func (c *cgroup) write(limits [][2]string) error {
	for _, l := range limits {
		file, value := l[0], l[1]
		path := filepath.Join(c.dirs[0], file)
		if len(c.dirs) > 1 {
			path = filepath.Join(cgroupRoot, file)
		}
		err := os.WriteFile(path, []byte(value), 0o644)
		if errors.Is(err, os.ErrNotExist) && filepath.Base(file) != "pids.max" {
			continue
		}
		if err != nil {
			return fmt.Errorf("set %s: %w", file, err)
		}
	}
	return nil
}

// procsFiles lists the cgroup.procs files the child must write itself into,
// joined with ":" so they fit in one environment variable.
func (c *cgroup) procsFiles() string {
	var files []string
	for _, d := range c.dirs {
		files = append(files, filepath.Join(d, "cgroup.procs"))
	}
	return strings.Join(files, string(os.PathListSeparator))
}

// remove deletes the cgroup directories. The kernel refuses while processes
// remain inside, so it runs only after the container has exited.
func (c *cgroup) remove() {
	for _, d := range c.dirs {
		os.Remove(d)
	}
}

// mountDev gives the container a private /dev holding the few device files
// most programs expect. The kernel knows each device by a major and minor
// number; 1,3 is /dev/null on every Linux system.
func mountDev() error {
	if err := os.MkdirAll("/dev", 0o755); err != nil {
		return err
	}
	if err := syscall.Mount("tmpfs", "/dev", "tmpfs", syscall.MS_NOSUID, "mode=755"); err != nil {
		return err
	}
	for name, minor := range map[string]int{"null": 3, "zero": 5, "random": 8, "urandom": 9} {
		dev := 1<<8 | minor // major 1, the "memory devices" driver
		if err := syscall.Mknod("/dev/"+name, syscall.S_IFCHR|0o666, dev); err != nil {
			return err
		}
		if err := os.Chmod("/dev/"+name, 0o666); err != nil { // undo the umask
			return err
		}
	}
	return nil
}

func exitWith(err error) {
	if exitErr, ok := err.(*exec.ExitError); ok {
		if ws, ok := exitErr.Sys().(syscall.WaitStatus); ok && ws.Signaled() {
			fmt.Fprintf(os.Stderr, "killed by signal: %v\n", ws.Signal())
			os.Exit(128 + int(ws.Signal()))
		}
		os.Exit(exitErr.ExitCode())
	}
	must(err)
	os.Exit(0)
}

func must(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
