# Glossary

Every term the book defines, in alphabetical order. Each entry gives the meaning in plain words and links to the chapter that introduces it. Where the chapter explains a term with an everyday picture, the entry names that picture too.

## Numbers

- **410 Gone**: the error a watch gets when it asks to start from a `resourceVersion` older than the API server still remembers. The client must list again. Everyday picture: a newspaper that no longer keeps last year's issues. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## A

- **Actual state**: what really exists and runs in the cluster right now. Everyday picture: the temperature the room is at. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Admission**: the API server's third check on a request that creates, changes or deletes an object, after authentication and authorization. Built-in checks inside the API server, and admission webhooks of your own, decide whether the object is acceptable, and may change it. Everyday picture: airport security checking what you carry. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Admission webhook**: a small web server of your own that the API server calls before it stores a new or changed object. A validating webhook can refuse the object; a mutating webhook can change it. Everyday picture: a mailroom clerk who checks each parcel before it goes on the shelf. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 9.
- **Agent**: a program that runs on its own and does work on someone else's behalf, such as the kubelet on each node. [Chapter 0](chapters/00-map-and-lab/README.md)
- **API** (application programming interface): the list of requests one program accepts from other programs. [Chapter 0](chapters/00-map-and-lab/README.md)
- **API server** (kube-apiserver): the hub of a cluster. It is the only program that reads and writes etcd, and every other part of Kubernetes, kubectl included, talks only to it, over HTTPS (HTTP protected by TLS). Everyday picture: the order rail in a restaurant kitchen, or a bank teller's window. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Archive file**: one file that holds many files packed together. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Authentication**: the API server's first check on a request: who is asking. Everyday picture: the passport desk at an airport. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Authorization**: the API server's second check on a request: may this user do this action on this resource. Everyday picture: the gate checking your ticket for this flight. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## B

- **base64**: a way to write any data using only plain letters, digits and a few symbols, so it fits in a text file. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **bash**: a common shell, the program that reads and runs the commands you type. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Binary**: a file that holds a ready-to-run program. Go builds one from your source code. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Bind mount**: making the same folder appear at a second place by mounting it there. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Binding**: the small object the scheduler sends to the API server to say which node a pod should run on. The API server then writes that node's name into the pod. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 5.
- **Bit and byte**: a bit is a single 0 or 1. A byte is 8 bits, enough to store one letter. Memory and files are measured in bytes. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Body**: the data part of an HTTP request or response, such as the JSON of an object. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Buffering**: saving up output and writing it out in chunks, instead of the moment it arrives. curl's `-N` flag turns it off. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **busybox**: a tiny Linux toolkit that packs `sh`, `ls`, `ps` and many other commands into one small program. Chapter 1 uses its files as a container's root filesystem. [Chapter 1](chapters/01-container-by-hand/README.md)

## C

- **Cache**: a copy of data kept in memory, so it can be read again quickly. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Capabilities**: the separate special powers of the Linux root user. A container runtime can take them away one by one. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Certificate**: a file that names a server, signed by a certificate authority. With TLS, a server proves who it is by showing its certificate. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Certificate authority**: a trusted signer that vouches for a server's certificate, so a client knows it reached the real API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **cgroup** (control group): a Linux kernel feature that caps how much memory, CPU and how many processes a group of processes may use. It shows up as a directory under `/sys/fs/cgroup`. Everyday picture: the circuit breaker for one hotel room. [Chapter 1](chapters/01-container-by-hand/README.md)
- **chroot**: a Linux system call that sets which directory a process treats as `/`, so it cannot name files outside it. Everyday picture: a hotel key that opens one room. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Client**: a program that sends requests to a server. kubectl and curl are both clients of the API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Cluster**: a group of machines that Kubernetes runs programs on. [Chapter 0](chapters/00-map-and-lab/README.md)
- **ClusterRole**: a role defined once for the whole cluster. A role binding can grant it inside one namespace. `view` is a built-in ClusterRole that allows only reads. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Command-line tool**: a program you run by typing its name in a terminal, not by clicking. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Compaction**: etcd throwing away its own old history of changes, to save space. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **ConfigMap**: an object that holds a few named settings. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Container**: an ordinary Linux process that the kernel shows a restricted view of the machine (namespaces) and holds to limits (cgroups). Every container on a node shares one kernel. Everyday picture: a room in a hotel. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Container runtime**: the program that starts containers. On kind nodes it is containerd; chapter 1 writes a small one. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Container Runtime Interface** (CRI): the standard API the kubelet uses to ask a container runtime, such as containerd, to start and stop containers. Everyday picture: a standard wall socket. [Chapter 1](chapters/01-container-by-hand/README.md)
- **containerd**: the container runtime on kind nodes. It downloads and unpacks images, and hands each container to an OCI runtime such as runc. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Control plane**: the set of programs that decide what runs and where: the API server, etcd, the scheduler and the controllers. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Controller**: a program that watches objects, compares the desired state with the actual state, and acts to close the gap, over and over. Everyday picture: a thermostat. [Chapter 0](chapters/00-map-and-lab/README.md)
- **CPU** (central processing unit): the chip that runs programs. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Credential**: the secret that proves who you are, such as a token. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **crictl**: a command-line tool for talking to containerd. `crictl ps` lists the containers on a node. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Cross-compiling**: building a program for a different operating system or chip than the one you build on. `GOOS=linux` asks Go to build for Linux. [Chapter 1](chapters/01-container-by-hand/README.md)
- **curl**: a command-line tool that sends web requests. [Chapter 0](chapters/00-map-and-lab/README.md)

## D

- **Database**: a program that stores records on disk and finds them again. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Deployment**: an object that says "keep this many copies of this pod running". When you change it, it replaces old pods with new ones a few at a time. A controller creates a ReplicaSet to do the counting. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Desired state**: what an object's spec asks for. Everyday picture: the temperature set on a thermostat. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Device file**: a special file in `/dev` that talks to a driver, kernel code that runs one kind of device. `/dev/null`, for example, throws away anything written to it. The kernel names each device with a major and a minor number. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Digest**: a fingerprint of a file's contents. The lab names its Kubernetes build by digest, so every reader runs the same bytes. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Discovery**: the API server endpoints, such as `/api/v1` and `/apis`, that list which resources exist and the path where each one lives. kubectl reads them to turn `kubectl get deploy` into a path. Everyday picture: the company board in an office lobby. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Docker**: a tool that runs containers. On a Mac you get it from an app such as Docker Desktop, OrbStack or Colima, which runs a small Linux virtual machine. [Chapter 0](chapters/00-map-and-lab/README.md)

## E

- **Endpoint**: a path that a server answers, such as `/version` on the API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Environment variable**: a named setting that a process passes on to the processes it starts. [Chapter 1](chapters/01-container-by-hand/README.md)
- **etcd**: the database that stores every Kubernetes object. It stores each value under a name, called its key. Only the API server talks to it. Everyday picture: the stack of order tickets a kitchen keeps. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Event**: one message a watch sends when an object changes. Its `type` is `ADDED`, `MODIFIED` or `DELETED`, or `ERROR` when something went wrong (some watches also send `BOOKMARK`). Kubernetes also has an object kind called Event, which is something else. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Exit code**: the number a command ends with. 0 means success. A process killed by signal 9 ends with 137. [Chapter 1](chapters/01-container-by-hand/README.md)

## F

- **File permissions**: who may read, write or run a file, written as three digits such as `755`: one digit for the owner, one for the owner's group and one for everyone else. Each digit adds 4 for read, 2 for write and 1 for run. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Filesystem**: the way the kernel arranges files and folders, on a disk or in memory. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Flag**: an option added to a command, starting with `-` or `--`, such as `-w`. [Chapter 0](chapters/00-map-and-lab/README.md)
- **fork and exec**: the two steps Linux uses to start a new program. `fork` copies the running process, and `exec` swaps the copy for the new program. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Function**: a named block of steps in a program. A Go program starts at the function `main`. Everyday picture: a recipe card. [Chapter 1](chapters/01-container-by-hand/README.md)

## G

- **Gateway**: the entry point for traffic from outside the cluster. It reads which site and page each request asks for and sends it to the right Service. Everyday picture: a hotel front desk. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 10.
- **git and GitHub**: git downloads code and keeps track of every change to it. GitHub is a web site that stores code. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Go runtime**: the support code every Go program runs, which does its work in several threads at once. [Chapter 1](chapters/01-container-by-hand/README.md)

## H

- **Header**: a labeled line that travels with an HTTP request or response, such as `Content-Type: application/json`. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Homebrew**: a tool that installs software on a Mac. Its command is `brew`. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Hostname**: the name a machine calls itself. [Chapter 1](chapters/01-container-by-hand/README.md)
- **HTTP**: the language web browsers and web sites use. The API server speaks it. A request has a method (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) and a path; a response has a status code and usually some JSON. Everyday picture: a form handed through a bank window, and its receipt. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## I

- **Image**: a packaged copy of every file a container's program needs. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Informer**: the part of a client that lists objects, then watches them, and keeps an up-to-date copy in memory. It lists again after `410 Gone`. [Chapter 2](chapters/02-api-server-with-curl/README.md), built in chapter 3.
- **IP address**: a number such as `10.244.1.5` that names one computer on a network. `127.0.0.1` always means "this computer". Everyday picture: a street address. [Chapter 0](chapters/00-map-and-lab/README.md)
- **iptables and nftables**: two ways to write network rules into the Linux kernel; nftables is the newer one. kube-proxy uses one of them. [Chapter 0](chapters/00-map-and-lab/README.md), built on in chapter 7.

## J

- **jq**: a command-line tool that reads JSON and picks out the parts you ask for, using a small filter language. [Chapter 0](chapters/00-map-and-lab/README.md)
- **JSON and YAML**: two plain-text formats that lay information out as named fields and values. JSON (JavaScript Object Notation) uses `{ }` for objects and `[ ]` for lists. Kubernetes objects are written in either. [Chapter 0](chapters/00-map-and-lab/README.md)

## K

- **Kernel**: the core of the operating system. Every process asks the kernel when it wants to read a file, start a process or use memory. [Chapter 0](chapters/00-map-and-lab/README.md)
- **kind** (Kubernetes in Docker): a tool that runs each Kubernetes node as a Docker container, so a whole cluster runs on a laptop with the real Kubernetes programs. Everyday picture: a flight simulator. [Chapter 0](chapters/00-map-and-lab/README.md)
- **kube-controller-manager**: the one program that runs all of Kubernetes' built-in controllers. [Chapter 0](chapters/00-map-and-lab/README.md)
- **kube-proxy**: the agent on each node that writes rules into the Linux kernel, so traffic sent to a Service's fixed address reaches one of its pods. The kernel carries the traffic; kube-proxy keeps the rules up to date. Everyday picture: the person who keeps a company switchboard's staff list current. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 7.
- **kubeadm**: the standard tool for installing the Kubernetes programs and connecting them to each other. kind uses it. [Chapter 0](chapters/00-map-and-lab/README.md)
- **kubeconfig**: the file that tells kubectl the API server's address and holds your credentials. kind writes it when it builds the cluster. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **kubectl**: the Kubernetes command-line tool. You type commands such as `kubectl get pods`, and it sends HTTP requests to the API server and prints the answers. Everyday picture: a customer at a bank window. [Chapter 0](chapters/00-map-and-lab/README.md)
- **kubectl proxy**: a kubectl command that listens on your machine, adds your kubeconfig's credentials to each request and forwards it to the API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **kubelet**: the agent on each node, one per node. It watches for pods assigned to its node, starts their containers through the container runtime, reports how they are doing and renews the node's Lease. It is the only part of Kubernetes that starts your programs. Everyday picture: the cook at one kitchen station. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 6.

## L

- **Label**: a short tag on an object, such as `chapter: two`, that you can search by. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Lease**: a small object the kubelet updates on a timer to show its node is alive. Everyday picture: a night guard's hourly call to the front desk. [Chapter 0](chapters/00-map-and-lab/README.md)
- **List**: a `GET` that returns every object of one kind at one moment, with the `resourceVersion` of that moment. Everyday picture: a trip to the newsstand. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## M

- **make and Makefile**: make runs named lists of commands that a project writes in a file called a Makefile. `make lab` runs the `lab` entry. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Memory**: where running programs keep their data while they work. Measured in bytes; a GB (gigabyte) is about a billion bytes, a MiB (mebibyte) is 1,048,576 bytes and a MB (megabyte) is 1,000,000. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Merge patch**: a `PATCH` request that sends only the fields to change, with the header `Content-Type: application/merge-patch+json`. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Method (Go)**: a function that belongs to a value, called as `value.name()`, such as `cg.remove()`. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Method (HTTP)**: the word at the start of an HTTP request that says what to do: `GET` reads, `POST` creates, `PUT` replaces, `PATCH` changes part, `DELETE` removes. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Mount**: attaching a filesystem at a directory, so its files appear there. Everyday picture: plugging in a USB stick. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Mount namespace**: a Linux namespace that gives a process its own copy of the mount table, so its mounts stay out of the host's list. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Mount table**: the kernel's list of every mount. [Chapter 1](chapters/01-container-by-hand/README.md)

## N

- **Namespace (Kubernetes)**: a named group of API objects, such as `ch02`. It has nothing to do with Linux namespaces. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Namespace (Linux)**: a kernel feature that gives a process its own copy of one thing the machine normally shares: the hostname (UTS), process numbers (PID), mounts, network and more. Everyday picture: the number on a hotel room door. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Network**: the connections that let programs on different computers, or the same one, send each other messages. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Node**: one machine in the cluster, real or virtual. On kind, each node is a Docker container. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Node lifecycle controller**: the controller that watches every node's Lease. When a Lease has not changed for 50 seconds, it sets the node's Ready status to Unknown, which kubectl shows as `NotReady`. [Chapter 0](chapters/00-map-and-lab/README.md)

## O

- **Object**: a short record, kept by the API server, that says what you want: a pod, a node, a Deployment. [Chapter 0](chapters/00-map-and-lab/README.md)
- **OCI runtime** (Open Container Initiative): a program, such as runc, that takes a root filesystem and a JSON config in the OCI format and starts a container from them. Everyday picture: the other side of a standard wall socket. [Chapter 1](chapters/01-container-by-hand/README.md)
- **OOM killer** (out-of-memory killer): the kernel code that picks a process to kill when memory runs out, either in a cgroup that hit its memory limit or on the whole computer. The process gets signal 9 and exits with code 137, and Kubernetes reports it as `OOMKilled`. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Operating system**: the base software that runs every other program, such as macOS, Windows or Linux. Its core is the kernel. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Optimistic concurrency**: letting writers work without a lock (a claim that makes everyone else wait), and rejecting any write made from an out-of-date copy, here with `409 Conflict`. The loser reads again and retries. Everyday picture: an office that rejects any copy of a form with an out-of-date revision stamp. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## P

- **Path**: the name of a file or folder, with `/` between folder names, such as `lab/kind-config.yaml`. On an API server, the part of a URL that names an object, such as `/api/v1/pods`. [Chapter 0](chapters/00-map-and-lab/README.md)
- **PID namespace**: a Linux namespace that gives a process its own process numbers, so the first process inside is number 1. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Pipe**: the `|` sign in the shell, which sends the output of one command into the next. Everyday picture: a factory line. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **pivot_root**: a stronger version of `chroot` that swaps the root for a whole mount namespace, so the old root can be removed. runc uses it. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Pod**: the smallest thing Kubernetes runs: one or more containers that share a node, a network address and storage. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Port**: a number that names one program on a computer, such as `8001`. Everyday picture: an apartment number. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Private and shared mounts**: a shared mount copies each new mount into other mount namespaces too (mount propagation); a private mount does not. systemd makes mounts shared, so a container runtime marks them private. [Chapter 1](chapters/01-container-by-hand/README.md)
- **/proc**: a special folder that the Linux kernel fills in as you read it, with facts about every process. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Process and pid**: a process is one running program; its pid (process ID) is the number Linux gives it. [Chapter 1](chapters/01-container-by-hand/README.md)

## Q

- **Quality-of-service class**: how firmly Kubernetes protects a pod's memory and CPU: Guaranteed, Burstable or BestEffort. A pod that asks for no memory or CPU is BestEffort. [Chapter 1](chapters/01-container-by-hand/README.md)

## R

- **Ready and NotReady**: a node's status. Ready means its kubelet reports that it can run pods. NotReady means it cannot, or that the control plane has not heard from it. [Chapter 0](chapters/00-map-and-lab/README.md)
- **ReplicaSet**: an object that keeps a set number of matching pods running. Its controller creates and deletes pods to hit the count. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 4.
- **Request and response**: a request is a message asking a server for something; the response is its answer. Everyday picture: a letter and its reply. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Resource**: one kind of object the API server serves, named by its plural, lowercase path, such as `pods`. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **resourceVersion**: a token on every object that changes on every write. Clients pass it back to watch from a known point or to refuse a write based on a stale read. Treat it as opaque: compare it only for equality. Everyday picture: the save number on a shared document, or the issue number of a newspaper. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Role and RoleBinding**: a Role lists the actions allowed on resources in one namespace. A ClusterRole is a role defined once for the whole cluster. A RoleBinding (role binding) grants a Role or a ClusterRole to a user or service account, inside one namespace. The built-in `view` ClusterRole allows only reads. Everyday picture: the doors a visitor badge opens. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Root filesystem**: the directory a container treats as `/`. In chapter 1 it is an exported busybox image. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Root user**: the administrator account of a Linux computer, allowed to do anything on it. [Chapter 0](chapters/00-map-and-lab/README.md)
- **runc**: the standard OCI runtime, which most others copy. It creates the namespaces and cgroups, sets up the root filesystem and starts the container's first process. [Chapter 1](chapters/01-container-by-hand/README.md)

## S

- **Scheduler** (kube-scheduler): the component that picks a node for each pod that has none, and writes its choice back as a Binding. It decides where a pod runs, but does not start it. Everyday picture: the kitchen manager who writes a station on each new ticket. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 5.
- **seccomp**: a Linux feature that filters which system calls a process may make. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Server**: a program that waits for requests and answers them. A web server answers requests for web pages and data. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Service**: an object that gives a set of pods one stable address. kube-proxy makes traffic to that address reach the pods. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 7.
- **Service account**: an identity for a program, not a person. The program proves it with a token. Everyday picture: a visitor badge. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Shell**: the program that reads the commands you type in a terminal and runs them, such as bash or zsh. Everyday picture: a very literal assistant. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Shell script**: a file of shell commands, run in order from top to bottom. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Signal**: a message the kernel sends to a process. Signal 9 means "stop now" and cannot be ignored. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Source code**: the written instructions a program is built from. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Status code**: the number on every HTTP response that says how it went: 200 OK, 401 Unauthorized, 403 Forbidden, 409 Conflict, 410 Gone. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Swap**: disk space that Linux can use as extra memory. [Chapter 1](chapters/01-container-by-hand/README.md)
- **System call**: a request a program makes to the kernel, such as `chroot` or `mount`. [Chapter 1](chapters/01-container-by-hand/README.md)
- **systemd**: the Linux program that starts other programs when the computer boots, and starts them again if they stop. [Chapter 0](chapters/00-map-and-lab/README.md)

## T

- **Terminal**: a window where you type commands and read what the computer prints back. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Thread**: a parallel line of work inside one process. On Linux each thread takes a number from the same pool as pids. [Chapter 1](chapters/01-container-by-hand/README.md)
- **TLS**: the encryption that protects `https` web sites, and every connection to the API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **tmpfs**: a small filesystem that lives in memory. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Token**: a short-lived credential a service account presents to the API server. Everyday picture: the badge itself. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## U

- **Umask**: a setting that removes some permissions from every new file Linux creates. [Chapter 1](chapters/01-container-by-hand/README.md)
- **URL**: a web address, such as `http://127.0.0.1:8001/api/v1`: how to talk (`http://`), which computer, which port and which path. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **UTS namespace**: a Linux namespace that gives a process its own hostname. [Chapter 1](chapters/01-container-by-hand/README.md)

## V

- **Variable**: a named box that holds a value. In Go, `x := 5` creates one. In the shell, `x=5` sets one and `$x` reads it. [Chapter 1](chapters/01-container-by-hand/README.md)
- **veth pair**: a virtual network cable with one end in each of two network namespaces. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Virtual machine**: a pretend computer, made in software, running inside a real one. [Chapter 0](chapters/00-map-and-lab/README.md)

## W

- **Watch**: a `GET` with `watch=true` that the API server holds open, sending one event per line (`ADDED`, `MODIFIED`, `DELETED`) each time an object changes. It starts from a `resourceVersion`. Everyday picture: a newspaper subscription. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Web server**: a program that waits for requests from other programs over a network and sends back answers, such as web pages. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Worker node**: a node that runs your pods. The lab has two, `lab-worker` and `lab-worker2`. [Chapter 0](chapters/00-map-and-lab/README.md)
- **WSL2** (Windows Subsystem for Linux 2): a Microsoft feature that runs Linux inside Windows. [Chapter 0](chapters/00-map-and-lab/README.md)
