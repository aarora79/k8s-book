# Glossary

Every term the book defines, in alphabetical order. Each entry gives the technical meaning, the everyday picture the chapter uses, and a link to the chapter that introduces it.

## Numbers

- **410 Gone**: the error a watch gets when it asks to start from a `resourceVersion` older than the API server still remembers. The client must list again. Everyday picture: a newspaper that no longer keeps last year's issues. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## A

- **Actual state**: what really exists and runs in the cluster right now. Everyday picture: the temperature the room is at. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Admission**: the API server's third check on a request, after authentication and authorization. Admission plugins and webhooks decide whether the object is acceptable, and may change it. Everyday picture: airport security checking what you carry. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Admission webhook**: an HTTPS server of your own that the API server calls during admission. A validating webhook says yes or no; a mutating webhook may change the object. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 9.
- **API server** (kube-apiserver): the hub of a cluster. It is the only component that reads and writes etcd, and every other component, kubectl included, talks only to it over HTTP. Everyday picture: the order rail in a restaurant kitchen, or a bank teller's window. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Authentication**: the API server's first check on a request: who is asking. Everyday picture: the passport desk at an airport. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Authorization**: the API server's second check on a request: may this user do this action on this resource. Everyday picture: the gate checking your ticket for this flight. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## B

- **Binding**: the object the scheduler writes to assign a pod to a node. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 5.
- **busybox**: a tiny Linux toolkit that packs `sh`, `ls`, `ps` and many other commands into one small program. Chapter 1 uses its files as a container's root filesystem. [Chapter 1](chapters/01-container-by-hand/README.md)

## C

- **Certificate authority**: a trusted signer that vouches for a server's certificate, so a client knows it reached the real API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **cgroup** (control group): a Linux kernel feature that caps how much memory, CPU and how many processes a group of processes may use. It shows up as a directory under `/sys/fs/cgroup`. Everyday picture: the circuit breaker for one hotel room. [Chapter 1](chapters/01-container-by-hand/README.md)
- **chroot**: a Linux system call that sets which directory a process treats as `/`, so it cannot name files outside it. Everyday picture: a hotel key that opens one room. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Client**: a program that sends requests to a server. kubectl and curl are both clients of the API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Cluster**: a group of machines that Kubernetes runs programs on. [Chapter 0](chapters/00-map-and-lab/README.md)
- **ConfigMap**: an object that holds a few named settings. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Container**: an ordinary Linux process that the kernel shows a restricted view of the machine (namespaces) and holds to limits (cgroups). Every container on a node shares one kernel. Everyday picture: a room in a hotel. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Container Runtime Interface** (CRI): the standard API the kubelet uses to ask a container runtime, such as containerd, to start and stop containers. Everyday picture: a standard wall socket. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Container runtime**: the program that starts containers. On kind nodes it is containerd; chapter 1 writes a small one. [Chapter 1](chapters/01-container-by-hand/README.md)
- **containerd**: the container runtime on kind nodes. It pulls and unpacks images and hands each container to an OCI runtime such as runc. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Control plane**: the set of programs that decide what runs and where: the API server, etcd, the scheduler and the controllers. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Controller**: a program that watches objects, compares the desired state with the actual state, and acts to close the gap, over and over. Everyday picture: a thermostat. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Credential**: the secret that proves who you are, such as a token. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Cross-compiling**: building a program for a different operating system or chip than the one you build on. `GOOS=linux` asks Go to build for Linux. [Chapter 1](chapters/01-container-by-hand/README.md)
- **curl**: a command-line tool that sends web requests. [Chapter 0](chapters/00-map-and-lab/README.md)

## D

- **Deployment**: an object that asks for a number of identical pods and manages rolling updates. The Deployment controller creates a ReplicaSet to do the counting. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Desired state**: what an object's spec asks for. Everyday picture: the temperature set on a thermostat. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Digest**: a fingerprint of a file's contents. The lab names its Kubernetes build by digest, so every reader runs the same bytes. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Discovery**: the API server endpoints, such as `/api/v1` and `/apis`, that list which resources live under which URL. kubectl reads them to turn `kubectl get deploy` into a path. Everyday picture: the company board in an office lobby. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## E

- **Environment variable**: a named setting that a process passes on to the processes it starts. [Chapter 1](chapters/01-container-by-hand/README.md)
- **etcd**: the key-value database that stores every Kubernetes object. Only the API server talks to it. Everyday picture: the stack of order tickets a kitchen keeps. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Event**: one line a watch sends when an object changes: `ADDED`, `MODIFIED`, `DELETED` or `ERROR`. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Exit code**: the number a command ends with. 0 means success. A process killed by signal 9 ends with 137. [Chapter 1](chapters/01-container-by-hand/README.md)

## H

- **Hostname**: the name a machine calls itself. [Chapter 1](chapters/01-container-by-hand/README.md)
- **HTTP**: the language web browsers and web sites use. The API server speaks it. A request has a method (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) and a path; a response has a status code and usually some JSON. Everyday picture: a form handed through a bank window, and its receipt. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## I

- **Image**: a packaged copy of every file a container's program needs. [Chapter 1](chapters/01-container-by-hand/README.md)

## J

- **JSON and YAML**: two plain-text formats for structured data. Kubernetes objects are written in either. [Chapter 0](chapters/00-map-and-lab/README.md)

## K

- **Kernel**: the core of the operating system. Every process asks the kernel when it wants to read a file, start a process or use memory. [Chapter 0](chapters/00-map-and-lab/README.md)
- **kind** (Kubernetes in Docker): a tool that runs each Kubernetes node as a Docker container, so a whole cluster runs on a laptop with the real Kubernetes programs. Everyday picture: a flight simulator. [Chapter 0](chapters/00-map-and-lab/README.md)
- **kubeconfig**: the file that tells kubectl the API server's address and holds your credentials. kind writes it when it builds the cluster. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **kubectl proxy**: a kubectl command that listens on your machine, adds your kubeconfig's credentials to each request and forwards it to the API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **kubectl**: the Kubernetes command-line tool. It is an HTTP client of the API server. Everyday picture: a customer at a bank window. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **kubelet**: the agent on each node. It watches for pods bound to its node, starts their containers through the container runtime, reports their status and renews the node's Lease. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 6.
- **kube-proxy**: the agent on each node that turns Services into kernel rules, so traffic sent to a Service's address reaches one of its pods. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 7.

## L

- **Label**: a short tag on an object, such as `chapter: two`, that you can search by. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Lease**: a small object the kubelet updates on a timer to show its node is alive. Everyday picture: a night guard's hourly call to the front desk. [Chapter 0](chapters/00-map-and-lab/README.md)
- **List**: a `GET` that returns every object of one kind at one moment, with the `resourceVersion` of that moment. Everyday picture: a trip to the newsstand. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## M

- **make and Makefile**: make runs named lists of commands that a project writes in a file called a Makefile. `make lab` runs the `lab` entry. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Merge patch**: a `PATCH` request that sends only the fields to change, with the header `Content-Type: application/merge-patch+json`. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Mount**: attaching a filesystem at a directory, so its files appear there. Everyday picture: plugging in a USB stick. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Mount namespace**: a Linux namespace that gives a process its own copy of the mount table, so its mounts stay out of the host's list. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Mount table**: the kernel's list of every mount. [Chapter 1](chapters/01-container-by-hand/README.md)

## N

- **Namespace (Kubernetes)**: a named group of API objects, such as `ch02`. It has nothing to do with Linux namespaces. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Namespace (Linux)**: a kernel feature that gives a process its own copy of one thing the machine normally shares: the hostname (UTS), process numbers (PID), mounts, network and more. Everyday picture: the number on a hotel room door. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Node lifecycle controller**: the controller that marks a node `NotReady` when its Lease stops changing. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Node**: one machine in the cluster, real or virtual. On kind, each node is a Docker container. [Chapter 0](chapters/00-map-and-lab/README.md)

## O

- **Object**: a short record, kept by the API server, that says what you want: a pod, a node, a Deployment. [Chapter 0](chapters/00-map-and-lab/README.md)
- **OCI runtime** (Open Container Initiative): a program, such as runc, that takes a root filesystem and a JSON config in the OCI format and starts a container from them. Everyday picture: the other side of a standard wall socket. [Chapter 1](chapters/01-container-by-hand/README.md)
- **OOM killer** (out-of-memory killer): the kernel code that kills a process when a cgroup goes over its memory cap. The process exits with code 137, and Kubernetes reports it as `OOMKilled`. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Optimistic concurrency**: letting writers work without a lock and rejecting any write based on a stale read, here with `409 Conflict`. The loser reads again and retries. Everyday picture: an office that rejects any copy of a form with an out-of-date revision stamp. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## P

- **PID namespace**: a Linux namespace that gives a process its own process numbers, so the first process inside is number 1. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Pod**: the smallest thing Kubernetes runs: one or more containers that share a node, a network address and storage. [Chapter 0](chapters/00-map-and-lab/README.md)
- **Process and pid**: a process is one running program; its pid (process ID) is the number Linux gives it. [Chapter 1](chapters/01-container-by-hand/README.md)

## R

- **ReplicaSet**: an object that keeps a set number of matching pods running. Its controller creates and deletes pods to hit the count. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 4.
- **resourceVersion**: a token on every object that changes on every write. Clients pass it back to watch from a known point or to refuse a write based on a stale read. Treat it as opaque: compare it only for equality. Everyday picture: the save number on a shared document, or the issue number of a newspaper. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Role and RoleBinding**: a Role lists actions allowed on resources in a namespace; a RoleBinding grants those actions to a user or service account. The built-in `view` role allows only reads. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Root filesystem**: the directory a container treats as `/`. In chapter 1 it is an exported busybox image. [Chapter 1](chapters/01-container-by-hand/README.md)
- **runc**: the reference OCI runtime. It creates the namespaces and cgroups, sets up the root filesystem and starts the container's first process. [Chapter 1](chapters/01-container-by-hand/README.md)

## S

- **Scheduler** (kube-scheduler): the component that picks a node for each pod that has none and writes a Binding. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 5.
- **Service account**: an identity for a program, not a person. The program proves it with a token. Everyday picture: a visitor badge. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Service**: an object that gives a set of pods one stable address. kube-proxy makes traffic to that address reach the pods. [Chapter 0](chapters/00-map-and-lab/README.md), built in chapter 7.
- **Signal**: a message the kernel sends to a process. Signal 9 means "stop now" and cannot be ignored. [Chapter 1](chapters/01-container-by-hand/README.md)
- **Status code**: the number on every HTTP response that says how it went: 200 OK, 401 Unauthorized, 403 Forbidden, 409 Conflict, 410 Gone. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **System call**: a request a program makes to the kernel, such as `chroot` or `mount`. [Chapter 1](chapters/01-container-by-hand/README.md)

## T

- **Thread**: a parallel line of work inside one process. On Linux each thread takes a number from the same pool as pids. [Chapter 1](chapters/01-container-by-hand/README.md)
- **TLS**: the encryption that protects `https` web sites, and every connection to the API server. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Token**: a short-lived credential a service account presents to the API server. Everyday picture: the badge itself. [Chapter 2](chapters/02-api-server-with-curl/README.md)

## U

- **UTS namespace**: a Linux namespace that gives a process its own hostname. [Chapter 1](chapters/01-container-by-hand/README.md)

## W

- **Watch**: a `GET` with `watch=true` that the API server holds open, sending one event per line (`ADDED`, `MODIFIED`, `DELETED`) each time an object changes. It starts from a `resourceVersion`. Everyday picture: a newspaper subscription. [Chapter 2](chapters/02-api-server-with-curl/README.md)
- **Worker node**: a node that runs your pods. The lab has two, `lab-worker` and `lab-worker2`. [Chapter 0](chapters/00-map-and-lab/README.md)
