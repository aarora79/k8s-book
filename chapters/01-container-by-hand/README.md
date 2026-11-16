# Chapter 1: A container by hand

Written for Kubernetes 1.34.0 (kind 0.30.0 node image), Go 1.24.

## What you will build

A container runtime in about 200 lines of Go. It runs a command with its own hostname, its own process numbers, its own root filesystem, its own mounts and a hard cap on processes and memory:

```text
$ step4 run /root/rootfs /bin/sh
parent: pid 4127, starting [/bin/sh]
child:  pid 1, running [/bin/sh]
/ # hostname
container
/ # ps
PID   USER     COMMAND
    1 root     /proc/self/exe child /root/rootfs /bin/sh
    6 root     /bin/sh
    7 root     ps
/ # for i in $(seq 1 40); do sleep 1 & done
/bin/sh: can't fork: Resource temporarily unavailable
```

A container is an ordinary Linux process that the kernel shows a restricted view of the machine. This chapter builds that view one piece at a time, and chapter 6 uses the result to run the pods your own kubelet receives.

The design follows Liz Rice's talk [Containers From Scratch](https://gotopia.tech/sessions/380/containers-from-scratch) ([code](https://github.com/lizrice/containers-from-scratch)).

## What the real one does

When the kubelet starts a pod, it asks the container runtime (containerd on kind nodes) over the Container Runtime Interface. containerd unpacks the image into a filesystem and hands a directory plus a JSON config to an OCI runtime, usually [runc](https://github.com/opencontainers/runc). runc does the work this chapter does by hand: it creates namespaces, joins cgroups, mounts `/proc` and `/dev`, switches the root filesystem and executes the container's first process.

runc also does much that this chapter skips: network, IPC and cgroup namespaces, user namespaces, dropping Linux capabilities, a seccomp filter on system calls, read-only and masked paths under `/proc`, and `pivot_root` in place of `chroot`. The design notes at the end cover why.

## Scope

| Supported | Left out |
| --- | --- |
| UTS namespace (hostname) | Network namespace: the container shares the node's network |
| PID namespace: the command sees itself near process 1 | IPC, cgroup and user namespaces |
| `chroot` into a busybox root filesystem | Images and layers: you unpack one image by hand |
| Mount namespace, private `/proc` and `/dev` | Capabilities, seccomp, AppArmor |
| cgroup limits on process count and memory, cgroup v1 and v2 | CPU limits, I/O limits |
| Exit codes and signals passed back to the caller | `pivot_root` |

## Set up

You need the lab from [chapter 0](../00-map-and-lab/README.md). Your runtime needs a Linux kernel, so the Makefile builds it for the node's CPU, copies it into `lab-worker` and runs it there:

```bash
cd chapters/01-container-by-hand
make install rootfs
```

`make install` cross-compiles `step1` to `step4` with `GOOS=linux` and copies them to `/usr/local/bin` on the node. `make rootfs` creates a busybox container on your Mac, exports its filesystem and unpacks it into `/root/rootfs` on the node. That directory is the only "image" this chapter uses.

Open a root shell on the node to follow along:

```bash
make shell
```

## Build it

### Step 1: a new hostname

The smallest container changes one thing: the hostname. A UTS namespace gives a process its own hostname, separate from the machine's.

The program starts itself twice. The first copy, `run`, asks the kernel to start the second copy, `child`, inside a new namespace. The child then sets the hostname and runs your command. The child has to exist because the namespace only applies to processes started inside it, and Go cannot run code between `fork` and `exec`.

From `step1/main.go`:

```go
// run starts this same program again as "child", inside a new UTS namespace.
func run(args []string) {
	fmt.Printf("parent: pid %d, starting %v\n", os.Getpid(), args)
	cmd := exec.Command("/proc/self/exe", append([]string{"child"}, args...)...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Cloneflags: syscall.CLONE_NEWUTS,
	}
	exitWith(cmd.Run())
}

// child runs inside the new namespace. It sets the hostname, then runs the
// user's command.
func child(args []string) {
	fmt.Printf("child:  pid %d, running %v\n", os.Getpid(), args)
	must(syscall.Sethostname([]byte("container")))

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	exitWith(cmd.Run())
}
```

`/proc/self/exe` always points at the running program's own binary, so `run` can start a copy of itself without knowing where it was installed. `exitWith` passes the command's exit code back up, so a failed command fails the whole runtime.

Run it on the node:

```bash
step1 run hostname
hostname
```

```text
parent: pid 1781, starting [hostname]
child:  pid 1786, running [hostname]
container
lab-worker
```

The command saw `container`; the node kept `lab-worker`. The child's pid, 1786, is an ordinary number on the node, because the child still shares the node's process list.

### Step 2: process 1 and a root filesystem

Two more changes make it feel like a container. A PID namespace gives the child its own process numbers, so the first process inside is number 1. `chroot` makes the busybox directory the child's `/`. A fresh `/proc` mount makes `ps` read the new process list instead of the node's.

The diff from step 1, in `step2/main.go`:

```go
	cmd.SysProcAttr = &syscall.SysProcAttr{
		// New: CLONE_NEWPID gives the child its own process numbers.
		Cloneflags: syscall.CLONE_NEWUTS | syscall.CLONE_NEWPID,
	}
```

```go
	// New: make rootfs the child's "/", then mount a fresh /proc so tools
	// like ps read this PID namespace instead of the host's.
	must(syscall.Chroot(rootfs))
	must(os.Chdir("/"))
	must(syscall.Mount("proc", "/proc", "proc", 0, ""))

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	err := cmd.Run()

	must(syscall.Unmount("/proc", 0))
	exitWith(err)
```

```bash
step2 run /root/rootfs /bin/sh -c 'echo "my pid is $$"; ps; ls /'
```

```text
parent: pid 1841, starting [/bin/sh -c echo "my pid is $$"; ps; ls /]
child:  pid 1, running [/bin/sh -c echo "my pid is $$"; ps; ls /]
my pid is 6
PID   USER     COMMAND
    1 root     /proc/self/exe child /root/rootfs /bin/sh -c echo "my pid is $$"; ps; ls /
    6 root     /bin/sh -c echo "my pid is $$"; ps; ls /
    7 root     {ps} /bin/sh -c echo "my pid is $$"; ps; ls /
bin
dev
etc
...
```

Your Go program is process 1. The shell got 6 because the Go runtime's threads took 2 to 5: threads draw from the same pool of numbers. `ls /` shows busybox's files, not the node's.

### Step 3: mounts of its own, and /dev

Step 2 has a leak. Its `/proc` mount lives in the node's mount table, and only the `Unmount` at the end removes it. Kill the container and the mount stays behind (see "Break it" below).

A mount namespace gives the child its own copy of the mount table. One more detail matters on hosts that run systemd, which includes kind nodes: systemd marks `/` as a shared mount, so new mounts propagate between namespaces anyway. The child marks every mount private first.

From `step3/main.go`:

```go
		// New: CLONE_NEWNS gives the child its own list of mounts.
		Cloneflags: syscall.CLONE_NEWUTS | syscall.CLONE_NEWPID | syscall.CLONE_NEWNS,
```

```go
	// New: hosts that run systemd share mounts between namespaces by default.
	// Mark every mount private so the /proc we mount below stays in here.
	must(syscall.Mount("", "/", "", syscall.MS_PRIVATE|syscall.MS_REC, ""))

	must(syscall.Chroot(rootfs))
	must(os.Chdir("/"))
	must(syscall.Mount("proc", "/proc", "proc", 0, ""))
	// New: a /dev of the container's own, also private to this namespace.
	must(mountDev())
```

The unmount at the end is gone. When the last process in the namespace exits, the kernel drops the namespace and its mounts with it.

Programs also expect a few files in `/dev`, and an exported image has none. `mountDev` mounts an empty `tmpfs` on `/dev` and creates four device files. The kernel identifies each device by a pair of numbers; major 1 is the driver for memory-backed devices, and minor 3 is `/dev/null` on every Linux system:

```go
	for name, minor := range map[string]int{"null": 3, "zero": 5, "random": 8, "urandom": 9} {
		dev := 1<<8 | minor // major 1, the "memory devices" driver
		if err := syscall.Mknod("/dev/"+name, syscall.S_IFCHR|0o666, dev); err != nil {
			return err
		}
```

### Step 4: limits

Namespaces control what a process can see. Control groups (cgroups) control how much it can use. A cgroup is a directory under `/sys/fs/cgroup`: you write limits into its files and process ids into its `cgroup.procs` file, and the kernel enforces the limits on every process listed and on all their children.

The parent creates the cgroup and writes the limits before the child starts. kind nodes use cgroup v2, where one directory holds every limit:

```go
		return cg, cg.write([][2]string{
			{"pids.max", strconv.Itoa(pids)},
			{"memory.max", mem},
			{"memory.swap.max", "0"},
		})
```

The child joins the cgroup before it runs anything else. Writing `0` to `cgroup.procs` means "the process doing the writing". The child cannot write its own pid, because inside the PID namespace its pid is 1, and the kernel would read that as the node's process 1:

```go
	// New: join the cgroup. Writing "0" to cgroup.procs moves the writer
	// itself. Everything it starts from now on inherits the limits.
	for _, f := range filepath.SplitList(os.Getenv("HMLK8S_CGROUP_PROCS")) {
		must(os.WriteFile(f, []byte("0"), 0o644))
	}
```

The parent passes the path in an environment variable, because the child runs as a fresh copy of the program and shares no memory with the parent. After the container exits, the parent removes the cgroup directory. `step4/main.go` also handles older cgroup v1 machines, where each controller has its own directory tree.

```bash
step4 run -pids 20 /root/rootfs /bin/sh -c 'for i in $(seq 1 40); do sleep 1 & done; wait'
step4 run -memory-mb 50 /root/rootfs /bin/sh -c 'x=$(head -c 200000000 /dev/zero | tr "\0" a)'
echo $?
```

```text
/bin/sh: can't fork: Resource temporarily unavailable
...
killed by signal: killed
137
```

The 21st process failed to start. The shell that tried to hold 200 MB in a 50 MiB cgroup got killed by the kernel's out-of-memory killer, and the runtime reported exit code 137, which is 128 plus signal 9. Kubernetes shows the same event as `OOMKilled`.

## Run it beside the real one

Run a pod on the same node and compare what containerd set up with what you set up:

```bash
kubectl run sleeper --image=busybox:1.37 --overrides='{"spec":{"nodeName":"lab-worker"}}' -- sleep 3600
docker exec lab-worker sh -c 'pid=$(pgrep -f "sleep 3600" | head -1); ls -l /proc/$pid/ns; cat /proc/$pid/cgroup'
docker exec lab-worker sh -c 'step4 run /root/rootfs /bin/sh -c "ls -l /proc/self/ns"'
```

Each namespace shows as a link like `pid:[4026532290]`. Two processes share a namespace when the numbers match. The pod's process has its own `net`, `ipc` and `cgroup` namespaces; yours shares those with the node. The pod's cgroup sits several levels under the kubelet's cgroup, grouped by quality-of-service class and pod id; yours sits at the top level as `hmlk8s-<pid>`.

Clean up with `kubectl delete pod sleeper`.

## Break it

1. Kill a step 2 container and look for its mount:

   ```bash
   step2 run /root/rootfs /bin/sleep 30 &
   sleep 1; pkill -9 -f 'exe child /root/rootfs'
   grep rootfs/proc /proc/self/mountinfo
   umount /root/rootfs/proc
   ```

   The `/proc` mount outlives the container. Repeat with `step3` and `grep` finds nothing.

2. Remove the `MS_PRIVATE` line from step 3, rebuild with `make install`, and run the same experiment. The mount namespace alone does not stop the leak on a systemd host.

3. Run `step4 run -pids 5 /root/rootfs /bin/sh -c 'ls | wc -l'`. Count how many processes that one line needs, including the runtime's own child.

## Design notes

**Why runc uses `pivot_root`.** `chroot` changes how one process resolves `/`, but the old root stays reachable: a root process inside can call `chroot` again on a subdirectory and walk back out with `..`. `pivot_root` swaps the root of the whole mount namespace and lets runc unmount the old one, so nothing outside remains. runc calls it inside the container's own mount namespace, so the swap changes nothing for the node.

**Why the double start.** runc has the same problem as step 1: some setup must happen inside the new namespaces but before the container's program starts. runc solves it with a small C function that runs before the Go runtime starts (`nsexec`), then re-executes itself, much like `/proc/self/exe child` here.

**Why cgroups v2 put everything in one directory.** In cgroup v1 each controller had its own tree, so a process could sit in different places for memory and for pids, and tools had to keep the trees in step. Version 2 has one tree. That is why the v2 branch in `newCgroup` is shorter than the v1 branch.

**What this does not protect.** Your container runs as the node's real root user, with every capability and no system-call filter. A process inside it can load kernel modules or reboot the node. User namespaces, dropped capabilities and seccomp exist to close those doors.

## Improving and expanding

1. Easy: add a `-cpu` flag that writes `cpu.max` (for example `50000 100000` for half a CPU) and test it with a busy loop and `top` on the node.
2. Medium: replace `chroot` with `pivot_root`. You need a bind mount of the rootfs onto itself first, because `pivot_root` requires the new root to be a mount point.
3. Medium: mount the rootfs read-only and give each run a writable `overlay` layer in a temporary directory, so two containers can share one image.
4. Medium: add `CLONE_NEWNET`, then create a veth pair from the parent with `ip link` and give the container an address. Chapter 7 returns to this plumbing.
5. Hard: read the `process.args`, `hostname` and `linux.resources` fields from an OCI `config.json`, so your runtime accepts the same input as runc.

## Further reading

- [Liz Rice, Containers From Scratch, GOTO 2018](https://gotopia.tech/sessions/380/containers-from-scratch)
- [runc](https://github.com/opencontainers/runc), the reference OCI runtime
- [Linux kernel documentation: Control Group v2](https://docs.kernel.org/admin-guide/cgroup-v2.html)
- `man 7 namespaces` and `man 7 mount_namespaces` on the node
