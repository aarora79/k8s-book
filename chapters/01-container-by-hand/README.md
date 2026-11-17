# Chapter 1: A container by hand

Written for Kubernetes 1.34.0 (kind 0.30.0 node image), Go 1.24.

## What you will build

A container runtime: the program that starts containers. Yours is about 200 lines of Go. By the end of the chapter it can start a shell that believes it has the machine to itself, and it can stop that shell from using too much memory or starting too many programs. Here is the finished runtime at work:

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

Read the output line by line. The shell asks for its machine's name, its hostname, and gets `container`, not the node's real name. It lists the running programs and sees only three. Then it tries to start 40 more and fails, because your runtime set a limit of 20.

First, two words. A process is one running program; Linux gives each process a number, its process ID or pid. The kernel, as chapter 0 said, is the core of the operating system: every process asks the kernel when it wants to read a file, start another process or use memory.

> **Everyday picture.** Guests in a hotel share one building, one water supply and one power line, but each room has its own number, its own key and its own circuit breaker, and no guest can see into the next room. Nobody builds a new hotel for each guest. **In Linux,** each container is a room. Every container on a node shares the one Linux kernel. The kernel gives each container its own view of the machine, using a feature called namespaces, and its own limits, using a feature called cgroups. This chapter builds both.

So a container is not a small virtual machine. It is an ordinary Linux process that the kernel shows a limited view of the machine. This chapter builds that view one piece at a time. In chapter 6, your own kubelet uses this runtime to run pods.

The design follows Liz Rice's talk [Containers From Scratch](https://gotopia.tech/sessions/380/containers-from-scratch) ([code](https://github.com/lizrice/containers-from-scratch)).

## What the real one does

In a real cluster, three programs share the work of starting a container, and they talk through two standards.

> **Everyday picture.** A wall socket follows a standard, so any lamp or kettle with the right plug works in any house. **In Kubernetes,** the Container Runtime Interface (CRI) is the socket between the kubelet and a container runtime such as containerd. The Open Container Initiative (OCI) runtime spec is a second socket, between containerd and a lower-level program called runc. Either side of each socket can be swapped for another program that fits the same standard.

Here is the chain. When the kubelet starts a pod, it asks containerd, over the CRI, to start the pod's containers. containerd fetches the container's image (a packaged copy of every file the program needs) and unpacks it into a folder. It then hands that folder, plus a settings file in JSON, to [runc](https://github.com/opencontainers/runc). runc does the work this chapter does by hand. It sets up the namespaces and cgroups, prepares the container's files, and starts the container's first process.

runc also does a lot that this chapter skips, mostly for security. It gives each container its own network, it takes away powers that the root user normally has, and it blocks dangerous requests to the kernel. The scope table below lists what you skip, and the design notes at the end explain the most important gaps.

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

You need the lab from [chapter 0](../00-map-and-lab/README.md). Your runtime uses Linux kernel features, so it has to run on Linux. The Makefile builds it on your Mac, copies it into the `lab-worker` node, and you run it there:

```bash
cd chapters/01-container-by-hand
make install rootfs
```

`make install` builds the four steps of this chapter, `step1` to `step4`. Your Mac runs macOS, so Go has to build Linux programs instead of Mac ones; this is called cross-compiling, and the setting `GOOS=linux` asks Go to do it. make then copies the four programs into `/usr/local/bin` on the node.

`make rootfs` gives your containers their files. It uses busybox, a tiny Linux toolkit that packs `sh`, `ls`, `ps` and many other commands into one small program. make starts a busybox container with Docker, copies out all its files, and unpacks them into the folder `/root/rootfs` on the node. That folder is the only image this chapter uses.

Open a root shell on the node to follow along:

```bash
make shell
```

## Build it

### Step 1: a new hostname

The smallest container changes one thing: the hostname, the name a machine calls itself.

> **Everyday picture.** A hotel has one street address, but the number on your door belongs to your room alone, and changing it does not change the building's address. **In Linux,** a namespace is that door number: the kernel gives a process its own copy of one thing the machine normally shares. Linux has several kinds of namespace. The UTS namespace gives a process its own hostname. (UTS is an old Unix name; it stands for "UNIX Time-sharing System".)

One warning about the word. Kubernetes also has namespaces, such as `ch02` in chapter 2. Those are folders for Kubernetes objects, and they have nothing to do with Linux namespaces.

Now the trick in the code. The program starts itself twice. The first copy, `run`, asks the kernel to start a second copy, `child`, inside a new namespace. The second copy sets the hostname and then runs your command.

Why start twice? Because the setup has to happen inside the new namespace, before your command starts. Linux starts a new program in two steps. First `fork` makes a copy of the running process, then `exec` swaps that copy for the new program. A C program can run its own setup code between those two steps. Go does not allow that, so instead the program restarts itself inside the namespace and does the setup at the start of that second copy.

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

`/proc/self/exe` is a special path that always leads to the file of the program that is running. With it, `run` can start a copy of itself without knowing where you installed it. Every command ends with a number, its exit code, where 0 means success. `exitWith` passes your command's exit code back up, so when your command fails, the runtime fails too.

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

Your command printed `container`, but the node kept its name, `lab-worker`. The child's pid is 1786, an ordinary number on the node. That is because the child still sees the node's full list of processes. Step 2 fixes that.

### Step 2: process 1 and a root filesystem

Three more changes make it feel like a container: its own process numbers, its own files, and a process list that shows only its own processes.

First, the process numbers. A PID namespace gives the child its own set of pids, so the first process inside is number 1, just as on a freshly started machine.

Second, the files. On Linux every file path starts at `/`, the root of the filesystem. The folder tree that starts there is the root filesystem.

> **Everyday picture.** A hotel key opens one room, and to the guest that room is the whole building: they cannot walk into a room they cannot open. **In Linux,** the container's root filesystem is the room. The `chroot` system call (a request a program makes to the kernel) sets which folder a process treats as `/`. After `chroot`, the process cannot even name a file outside that folder. The design notes explain where this picture breaks down.

Here the busybox folder becomes the child's `/`.

Third, the process list. Tools like `ps` read the list of processes from `/proc`, a folder the kernel fills in as you read it. The child gets a fresh `/proc` that shows only the processes in its own PID namespace.

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

Your Go program is process 1. Why did the shell get 6 and not 2? A Go program does its work in several threads (parallel lines of work inside one process), and on Linux each thread takes a number from the same pool as processes. The Go program's threads took 2 to 5. Last, `ls /` shows busybox's files, not the node's.

### Step 3: mounts of its own, and /dev

Step 2 has a leak, and to see it you need one more word.

> **Everyday picture.** Plug a USB stick into a laptop and its files appear under one folder; unplug it and they vanish. **In Linux,** attaching a set of files at a folder is called mounting, and the kernel keeps a list of every mount, the mount table. A mount namespace gives a process its own copy of the mount table, so what it attaches stays out of everyone else's list.

Step 2 mounted the fresh `/proc`, but it had no mount namespace. So that mount went into the node's own mount table, and only the `Unmount` line at the end of the program takes it out again. Kill the container before that line runs, and the mount stays behind on the node. "Break it" below shows this.

Step 3 adds a mount namespace. One more detail matters here. On machines that run systemd, which includes kind nodes, systemd marks every mount as shared. A shared mount copies new mounts into other namespaces, which would undo the point of the namespace. So the child first marks every mount private.

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

The `Unmount` at the end is gone. When the last process in the namespace exits, the kernel throws away the namespace, and its mounts go with it.

Programs also expect a few special files in `/dev`, such as `/dev/null`, which throws away anything written to it. Our busybox folder has an empty `/dev`. So `mountDev` mounts a `tmpfs` there (a small filesystem that lives in memory) and creates four device files in it. The kernel names each device with two numbers. The first, the major number, picks the driver; major 1 is the driver for memory devices. The second, the minor number, picks the device; on every Linux system, major 1 with minor 3 is `/dev/null`:

```go
	for name, minor := range map[string]int{"null": 3, "zero": 5, "random": 8, "urandom": 9} {
		dev := 1<<8 | minor // major 1, the "memory devices" driver
		if err := syscall.Mknod("/dev/"+name, syscall.S_IFCHR|0o666, dev); err != nil {
			return err
		}
```

### Step 4: limits

Namespaces control what a process can see. Control groups, or cgroups, control how much it can use.

> **Everyday picture.** Each hotel room has its own circuit breaker. A guest who runs three heaters at once trips their own breaker and loses power, and the rest of the floor never notices. **In Linux,** a cgroup is that breaker for a group of processes. It caps how much memory and CPU they use and how many processes they start. When a container goes over its memory cap, the kernel kills a process in it.

You work with a cgroup through ordinary files. Each cgroup is a folder under `/sys/fs/cgroup`. You write a limit into one of its files, and you write a pid into its `cgroup.procs` file to put that process in the group. From then on, the kernel holds that process, and every process it starts, to the limits.

The parent creates the cgroup and writes the limits before the child starts. Linux has two versions of cgroups. kind nodes use version 2, where one folder holds every limit:

```go
		return cg, cg.write([][2]string{
			{"pids.max", strconv.Itoa(pids)},
			{"memory.max", mem},
			{"memory.swap.max", "0"},
		})
```

The child puts itself in the cgroup before it runs anything else. It writes `0` to `cgroup.procs`, and `0` there means "the process doing the writing". Why not write its own pid? Because inside the PID namespace the child's pid is 1, and the kernel would read that as the node's process 1, the wrong process:

```go
	// New: join the cgroup. Writing "0" to cgroup.procs moves the writer
	// itself. Everything it starts from now on inherits the limits.
	for _, f := range filepath.SplitList(os.Getenv("HMLK8S_CGROUP_PROCS")) {
		must(os.WriteFile(f, []byte("0"), 0o644))
	}
```

How does the child know which cgroup to join? The parent tells it through an environment variable, a named setting that a process passes on to the processes it starts. The parent cannot share a Go variable, because the child is a fresh copy of the program with its own memory. When the container exits, the parent deletes the cgroup folder. `step4/main.go` also works on older machines that use cgroup version 1, where each kind of limit has its own folder tree.

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

The first command hit the limit of 20 processes, so the 21st failed to start. In the second command, the shell tried to hold 200 MB in a cgroup capped at 50 MiB (a mebibyte, MiB, is 1,048,576 bytes). The kernel's out-of-memory killer stopped it. A process that is killed this way gets signal 9, a "stop now" message from the kernel, and its exit code becomes 128 plus 9, so 137. Kubernetes reports the same event as `OOMKilled`, where OOM stands for out of memory.

## Run it beside the real one

Now compare your runtime with the real one. Start a pod on the same node, then look at what containerd set up for it and what your runtime sets up:

```bash
kubectl run sleeper --image=busybox:1.37 --overrides='{"spec":{"nodeName":"lab-worker"}}' -- sleep 3600
docker exec lab-worker sh -c 'pid=$(pgrep -f "sleep 3600" | head -1); ls -l /proc/$pid/ns; cat /proc/$pid/cgroup'
docker exec lab-worker sh -c 'step4 run /root/rootfs /bin/sh -c "ls -l /proc/self/ns"'
```

The folder `/proc/<pid>/ns` holds one entry per namespace, shown as a link such as `pid:[4026532290]`. Two processes share a namespace when those numbers match. Compare the lists. The pod's process has its own `net`, `ipc` and `cgroup` namespaces: its own network, its own channels for talking to other processes, and its own view of the cgroup tree. Your container shares all three with the node.

Then compare the cgroups. The pod's cgroup sits several folders deep under the kubelet's cgroup, grouped first by the pod's quality-of-service class (how firmly Kubernetes protects the pod's memory and CPU) and then by the pod's id. Yours sits at the top level, named `hmlk8s-<pid>`.

Clean up with `kubectl delete pod sleeper`.

## Break it

1. Kill a step 2 container and look for its mount:

   ```bash
   step2 run /root/rootfs /bin/sleep 30 &
   sleep 1; pkill -9 -f 'exe child /root/rootfs'
   grep rootfs/proc /proc/self/mountinfo
   umount /root/rootfs/proc
   ```

   `pkill -9` kills the container at once, so the `Unmount` line never runs. `grep` then finds the `/proc` mount still on the node: it outlived the container. The last line removes it by hand. Repeat with `step3`, and `grep` finds nothing.

2. Delete the `MS_PRIVATE` line from step 3, rebuild with `make install`, and run the same experiment again. The leak is back. On a machine that runs systemd, a mount namespace alone does not stop it.

3. Run `step4 run -pids 5 /root/rootfs /bin/sh -c 'ls | wc -l'` with a limit of 5 processes. Does it work? Count how many processes that one line needs, and remember to count the runtime's own child.

## Design notes

**Why runc uses `pivot_root` and not `chroot`.** Here the hotel picture breaks down. `chroot` changes where one process starts its paths, but the node's real files are still there underneath. A process running as root inside the container can call `chroot` again on a folder below it, then climb back out with `..` until it reaches the node's files. `pivot_root` is stronger. It swaps the root for the whole mount namespace, and then runc unmounts the old root, so the node's files are gone from the container's view entirely. runc does this inside the container's own mount namespace, so the node itself is not affected.

**Why the double start.** runc is written in Go too, so it has the same problem as step 1: some setup must happen inside the new namespaces, but before the container's program starts. runc solves it with a small function written in C, called `nsexec`, that runs before Go itself starts up. Then runc starts itself again, much like `/proc/self/exe child` here.

**Why cgroup version 2 puts everything in one folder.** In version 1, each kind of limit had its own folder tree. A process could sit in one place in the memory tree and somewhere else in the process-count tree, and tools had to keep the trees matched by hand. Version 2 has one tree for every limit. That is why the version 2 code in `newCgroup` is shorter than the version 1 code.

**What this does not protect.** Your container runs as the node's real root user, with all of root's powers, and the kernel answers every request it makes. A process inside it can add code to the kernel or restart the node. runc blocks this in three ways. User namespaces make root inside the container an ordinary user outside it. Dropping capabilities takes away root's special powers one by one. seccomp filters the requests a process may make to the kernel.

## Improving and expanding

1. Easy: add a `-cpu` flag that writes the cgroup file `cpu.max`. The value `50000 100000` means 50,000 microseconds of CPU in every 100,000, so half a CPU. Test it with a loop that never stops, and watch it with `top` on the node.
2. Medium: replace `chroot` with `pivot_root`. First mount the root filesystem folder onto itself (a bind mount), because `pivot_root` only accepts a folder that is a mount.
3. Medium: let two containers share one image. Make the busybox folder read-only, and give each run its own writable layer on top with an `overlay` mount in a temporary folder.
4. Medium: give the container its own network. Add `CLONE_NEWNET`, then use `ip link` in the parent to create a veth pair, a virtual network cable with one end in the node and one in the container, and give the container an address. Chapter 7 returns to this.
5. Hard: read the `process.args`, `hostname` and `linux.resources` fields from an OCI `config.json` settings file, so your runtime takes the same input as runc.

## Further reading

- [Liz Rice, Containers From Scratch, GOTO 2018](https://gotopia.tech/sessions/380/containers-from-scratch)
- [runc](https://github.com/opencontainers/runc), the reference OCI runtime
- [Linux kernel documentation: Control Group v2](https://docs.kernel.org/admin-guide/cgroup-v2.html)
- `man 7 namespaces` and `man 7 mount_namespaces` on the node
