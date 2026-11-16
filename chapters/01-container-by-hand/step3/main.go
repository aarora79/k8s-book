// Command step3 adds a mount namespace, so the mounts the container makes stay
// inside it and vanish when it exits, even if it is killed.
//
// Usage: step3 run <rootfs> <command> [args...]
package main

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
)

func main() {
	if len(os.Args) < 4 {
		fmt.Fprintln(os.Stderr, "usage: step3 run <rootfs> <command> [args...]")
		os.Exit(2)
	}
	switch os.Args[1] {
	case "run":
		run(os.Args[2], os.Args[3:])
	case "child":
		child(os.Args[2], os.Args[3:])
	default:
		fmt.Fprintf(os.Stderr, "unknown command %q\n", os.Args[1])
		os.Exit(2)
	}
}

func run(rootfs string, args []string) {
	fmt.Printf("parent: pid %d, starting %v\n", os.Getpid(), args)
	cmd := exec.Command("/proc/self/exe", append([]string{"child", rootfs}, args...)...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{
		// New: CLONE_NEWNS gives the child its own list of mounts.
		Cloneflags: syscall.CLONE_NEWUTS | syscall.CLONE_NEWPID | syscall.CLONE_NEWNS,
	}
	exitWith(cmd.Run())
}

func child(rootfs string, args []string) {
	fmt.Printf("child:  pid %d, running %v\n", os.Getpid(), args)
	must(syscall.Sethostname([]byte("container")))

	// New: hosts that run systemd share mounts between namespaces by default.
	// Mark every mount private so the /proc we mount below stays in here.
	must(syscall.Mount("", "/", "", syscall.MS_PRIVATE|syscall.MS_REC, ""))

	must(syscall.Chroot(rootfs))
	must(os.Chdir("/"))
	must(syscall.Mount("proc", "/proc", "proc", 0, ""))
	// New: a /dev of the container's own, also private to this namespace.
	must(mountDev())

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	// No unmount needed: the mount namespace, and /proc with it, goes away
	// when the last process in it exits.
	exitWith(cmd.Run())
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
