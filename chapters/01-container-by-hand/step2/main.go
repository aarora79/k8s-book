// Command step2 adds a PID namespace and a root filesystem. The command sees
// itself as process 1 and sees only the files under <rootfs>.
//
// Usage: step2 run <rootfs> <command> [args...]
package main

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
)

func main() {
	if len(os.Args) < 4 {
		fmt.Fprintln(os.Stderr, "usage: step2 run <rootfs> <command> [args...]")
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
		// New: CLONE_NEWPID gives the child its own process numbers.
		Cloneflags: syscall.CLONE_NEWUTS | syscall.CLONE_NEWPID,
	}
	exitWith(cmd.Run())
}

func child(rootfs string, args []string) {
	fmt.Printf("child:  pid %d, running %v\n", os.Getpid(), args)
	must(syscall.Sethostname([]byte("container")))

	// New: make rootfs the child's "/", then mount a fresh /proc so tools
	// like ps read this PID namespace instead of the host's.
	must(syscall.Chroot(rootfs))
	must(os.Chdir("/"))
	must(os.MkdirAll("/proc", 0o755))
	must(syscall.Mount("proc", "/proc", "proc", 0, ""))

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	err := cmd.Run()

	must(syscall.Unmount("/proc", 0))
	exitWith(err)
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
