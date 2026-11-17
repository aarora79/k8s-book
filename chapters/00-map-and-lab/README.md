# Chapter 0: The map and the lab

This chapter was written and tested with Kubernetes 1.34.0, kind 0.30.0 and Go 1.24. You install all three in this chapter, and you will learn what each one is before you install it.

## What you will build

Kubernetes is a system for running programs on a group of computers. You tell it what you want running, for example "three copies of this web server", and it does the rest. (A web server is a program that waits for requests from other programs over a network and sends back answers, such as web pages.) Kubernetes starts the copies, places each one on a computer with room for it, and starts a copy again if it stops.

Kubernetes has a word for each of these things. The group of computers is a cluster, and each computer in the cluster is a node.

In this chapter you set up the lab: a small Kubernetes cluster with three nodes, running on your own laptop. Every later chapter uses it. You also get a map of Kubernetes, so you know what each part does and which chapter rebuilds it.

At the end of the chapter you type one command, `make check`, and it tests the lab. On a Mac it ends like this:

```text
Cluster
  ok    kind cluster 'lab' exists
  ok    API server is v1.34.0
  ok    3 of 3 nodes Ready
  ok    can run commands inside lab-worker (arch aarch64)

The lab is ready.
```

Each `ok` line is one test that passed. Do not worry about the words in it yet: you meet every one of them in this chapter.

## Before you start

This book assumes nothing about your computer skills. If you already use a terminal every day and know what a port is, skip ahead to "The map".

### The terminal

You give every instruction in this book by typing it, not by clicking. You type into a terminal: a window where you type a command, press Enter, and read what the computer prints back. On a Mac, open the app called Terminal (press Command and Space, type "Terminal" and press Enter). On Linux, open your terminal app. On Windows, you use a Linux terminal inside Windows, which "Set up" explains below.

> **Everyday picture.** Texting a very literal assistant. You send one exact instruction, the assistant does exactly that and replies, and then waits for the next instruction. It never guesses what you meant.
>
> **In the terminal,** each instruction is a command. The program that reads your commands and runs them is called the shell; bash and zsh are two common shells. The shell prints its reply, then waits for your next command.

A few things you will see in every command in this book:

- A command starts with the name of a program, such as `kubectl` or `docker`, then words that tell the program what to do: `kubectl get nodes` asks kubectl to get the list of nodes.
- A flag is an option added to a command. It starts with `-` or `--`, for example `-w` or `--format`. Each flag in this book is explained where it first appears.
- Text after a `#` in a command block is a note for you. The shell ignores it.
- The `|` sign, called a pipe, sends the output of one command into the next one. `head -5`, for example, keeps only the first five lines of whatever is piped into it.
- Some commands keep running until you stop them. To stop one, press Control and C together, written Ctrl+C.
- A path names a file or folder, with `/` between the folder names, such as `lab/kind-config.yaml`: the file `kind-config.yaml` inside the folder `lab`.

### Computers that talk to each other

Programs often talk to programs on other computers, or on the same computer, by sending messages over a network. Three words come up all the time.

> **Everyday picture.** Posting a letter to a big apartment block. The street address gets the letter to the right building, and the apartment number gets it to the right door. The person who opens the door reads your letter and posts a reply back to you.
>
> **In networking,** the street address is an IP address, a number such as `10.244.1.5` that names one computer on a network. The apartment number is a port, a number that names one program on that computer. A message asking for something is a request, and the answer is a response.

A program that waits for requests and answers them is a server. A program that sends requests is a client. Many programs, including every part of Kubernetes, send their requests in HTTP, the same message format that web browsers use to ask web sites for pages. Chapter 2 looks at HTTP closely.

### The operating system, the kernel and the hardware

The operating system is the base software that runs every other program: macOS on a Mac, Windows, or Linux. Its core is the kernel, the part that controls the hardware and decides which program may use what. Every running program asks the kernel when it wants to read a file, use memory or talk to the network. Kubernetes nodes run Linux, so this book is mostly about the Linux kernel.

Two pieces of hardware come up often. The CPU (central processing unit) is the chip that runs programs. Memory is where running programs keep their data while they work. Memory is measured in bytes; a GB (gigabyte) is about a billion bytes.

## The map

Here is the whole of Kubernetes on one page. Each box is one part, and the note under it names the chapter where you rebuild that part. Do not worry about the names yet. Look at the shape: one box in the middle, the API server, and every other part connected only to it. The rest of this section explains every name on the map, one at a time.

![The map: kubectl sends requests to the API server; the API server alone talks to etcd and calls admission webhooks; controllers, scheduler, kubelet, kube-proxy and gateway all watch the API server.](images/map.svg)

### The words you need first

Kubernetes has its own words for the things it runs. You need four of them before the map makes sense.

- A container is a program packed with everything it needs to run, kept apart from the other programs on the same computer. Chapter 1 builds one by hand, so for now think of a container as one running program.
- A pod is the unit Kubernetes runs. It holds one container, or a few containers that must run together on the same node.
- The control plane is the set of programs that make the decisions: what should run, and where. In your lab it runs on one node, named `lab-control-plane`.
- The worker nodes are the nodes that run your pods. Your lab has two, named `lab-worker` and `lab-worker2`.

Kubernetes keeps a record of everything you ask for, and calls each record an object. A pod is an object, and so is a node. You write objects in JSON or YAML, two plain-text formats that lay information out as named fields and values. In YAML, for example, the line `name: lab-worker` gives the field `name` the value `lab-worker`.

### One hub

Kubernetes has one hub, the API server. API stands for application programming interface: the list of requests one program accepts from other programs. The API server is the one program that every other part of Kubernetes talks to.

The API server keeps every object in a database, a program that stores records on disk and finds them again. Kubernetes uses a database called etcd, and the API server is the only program that reads or writes it.

You talk to the API server with kubectl, the Kubernetes command-line tool, which means a program you run by typing its name in a terminal. When you type `kubectl get pods`, kubectl sends a request to the API server and prints the answer. The other parts of Kubernetes send requests to the API server too, but from inside programs. None of them call each other. They only talk to the API server.

> **Everyday picture.** In a restaurant kitchen, the waiter clips each order ticket to a rail above the counter. The cooks never talk to the waiter or to each other. Each cook reads the rail, takes the tickets for their station and marks them done, and the stack of tickets is the only record of what the kitchen owes.
>
> **In Kubernetes,** the API server is the rail, etcd is the stack of tickets it keeps, and each part of Kubernetes is a cook that watches for its own kind of ticket.

### The parts on the map

Here is what each part of Kubernetes does. You meet each one properly in its own chapter.

**The scheduler** picks a node for each new pod. When a pod has no node yet, the scheduler looks at every node, drops the ones without enough free memory or CPU, picks the best of the rest, and writes its choice back to the API server. It does not start the pod; it only decides where the pod goes. You build one in chapter 5.

> **Everyday picture.** In the restaurant kitchen, the kitchen manager reads each new ticket that has no station written on it yet. The manager checks which stations have a free burner, writes a station on the ticket, and clips it back on the rail. The manager never cooks.
>
> **In Kubernetes,** the scheduler is the kitchen manager, a pod is a ticket, and a node is a cooking station.

**The kubelet** is an agent, a program that runs on its own and does work on someone else's behalf. There is one kubelet on every node. It watches the API server for pods that the scheduler assigned to its own node. When it sees one, it starts that pod's containers, keeps an eye on them, and reports back how they are doing: starting, running, or stopped. The kubelet is the only part of Kubernetes that starts your programs. You build one in chapter 6, using the container code from chapter 1.

> **Everyday picture.** Each cooking station has its own cook. The cook watches the rail for tickets marked with their station, cooks those dishes, and writes on each ticket how it is going: "cooking", "ready", "burnt". A cook never takes a ticket meant for another station.
>
> **In Kubernetes,** the kubelet is the cook at one station. Every node runs its own kubelet, and each kubelet starts only the pods assigned to its node.

**kube-proxy** is a second agent on every node, and it handles network traffic, the messages that travel between programs.

Here is the problem it solves. Pods come and go, and each new pod gets a new IP address. So a program that wants to talk to "the web server pods" cannot keep a list of their addresses: the list keeps changing. Kubernetes solves this with a Service, an object that gives a group of pods one fixed address that never changes.

kube-proxy makes that fixed address work. It watches the API server for Services and for the pods behind them. Then it writes rules into the Linux kernel, so that any message sent to the Service's address goes to one of its pods. kube-proxy does not carry the messages itself. The kernel does, by following kube-proxy's rules. You build your own kube-proxy in chapter 7.

> **Everyday picture.** A company publishes one phone number. Callers always dial that number, and the switchboard forwards each call to a staff member who is free. Staff join and leave, but the published number never changes. Someone has to keep the switchboard's list of staff up to date.
>
> **In Kubernetes,** the Service's address is the published number, the pods are the staff, the kernel is the switchboard, and kube-proxy is the person who keeps the switchboard's list up to date.

**Controllers** keep things the way you asked. For example, when you ask for three copies of a pod, a controller counts how many exist and creates or deletes pods until there are three. Kubernetes has dozens of controllers, each with one job. The next section shows how they work. You build one in chapter 4 and another in chapter 8.

**Admission webhooks** check each new or changed object before the API server stores it. A webhook is a small web server of your own that the API server sends the object to. It can refuse the object, or change it. For example, it can refuse a pod that has no memory limit (the most memory its containers may use), or it can add a label to it (a short tag such as `app: web`).

> **Everyday picture.** In an office mailroom, a clerk checks every parcel before it goes on the shelf. The clerk can send back a parcel with no return address, or stick a missing room number on one before shelving it.
>
> **In Kubernetes,** the shelf is etcd, the parcels are objects, and an admission webhook is the clerk: it can refuse an object or change it before the API server stores it. You build both kinds of webhook in chapter 9.

**A gateway** lets traffic from outside the cluster reach your pods. A request arrives from the internet, the gateway reads which web site and which page it asks for, and sends it to the right Service inside the cluster. You build one in chapter 10.

> **Everyday picture.** At a hotel, outside visitors do not wander the halls. They stop at the front desk, say who they came to see, and the desk sends them to the right room.
>
> **In Kubernetes,** the gateway is the front desk, the visitors are requests from outside the cluster, and the rooms are your Services.

### Every part runs the same loop

> **Everyday picture.** A thermostat holds a target temperature. It reads the room, compares it with the target and turns the heating on or off to close the gap. It does not care how the room got cold, and it keeps checking after the room is warm.
>
> **In Kubernetes,** an object is the target (the desired state), what is running now is the room (the actual state), and a program that closes the gap in a loop is a controller.

Every part on the map works like that thermostat. It watches the API server for the objects it cares about. It compares what those objects ask for with what exists. Then it acts to close the gap, and writes what it did back to the API server, where the next part sees it.

### Follow one request

Here is what happens when you ask for three copies of a web server. You do it with a Deployment, an object that says "keep this many copies of this pod running".

1. You write the Deployment in a YAML file and run `kubectl apply -f web.yaml`. The `-f` flag names the file. kubectl sends the Deployment to the API server, and the API server stores it in etcd. In chapter 2 you send requests like this one by hand, with curl, a command-line tool that sends HTTP requests.
2. A controller sees the new Deployment. It creates a ReplicaSet, an object whose only job is to keep a count of pods with a certain label. A second controller sees the ReplicaSet, counts zero pods with that label, and creates three Pod objects. Nothing runs yet; these are only records. You build this second controller in chapter 4.
3. The scheduler sees three pods with no node. It picks a node for each one, and sends its choice to the API server in a small object called a Binding. The API server then writes the node's name into the pod. You build a scheduler in chapter 5.
4. The kubelet on each chosen node sees a pod assigned to it, and starts the pod's containers. You build a kubelet in chapter 6.
5. You create a Service for the three pods. kube-proxy sees it, and writes kernel rules so that messages sent to the Service's address reach one of the pods. You build this in chapter 7.

Notice that no step calls the next one. Each part writes to the API server, and the next part notices. That is why you can swap any one part for a program of your own. This book does that, one part per chapter.

## Scope

| This book covers | This book leaves out |
| --- | --- |
| One cluster on one laptop, with three nodes | Clusters with several control-plane nodes, which keep running when one fails |
| Kubernetes 1.34.0, installed by kind 0.30.0 | Other versions, and other tools that run Kubernetes on a laptop, such as minikube and k3d |
| Macs with Apple chips, Linux, and Windows through WSL2 (Windows Subsystem for Linux 2, a Microsoft feature that runs Linux inside Windows) | Clusters rented from a cloud provider, a company such as Amazon or Google that rents out computers over the internet |

## Set up

### The tools and what each one does

You need eight tools. Here is what each one is for, before you install any of them.

- git downloads code and keeps track of every change to it. This book's code lives on GitHub, a web site that stores code, and you use git to download a copy.
- Homebrew installs software on a Mac. You use it to install three of the tools below. Its command is `brew`.
- Go is the programming language you write every program in this book with.
- kubectl is the Kubernetes command-line tool from the map above.
- curl sends HTTP requests from the terminal. It comes with macOS and with most Linux systems, so you probably have it already.
- jq reads JSON and picks out the parts you ask for. Chapter 2 uses it a lot.
- Docker runs containers on your laptop. On a Mac you get it by installing one of three apps: Docker Desktop, OrbStack or Colima. Any one of the three works, and this book calls whichever one you pick "your Docker app".
- kind builds a Kubernetes cluster out of Docker containers. Its name stands for "Kubernetes in Docker".
- make runs a named list of commands that a project writes down in a file called a Makefile. When this book says `make lab`, make looks up the entry called `lab` in the Makefile and runs the commands listed there.

> **Everyday picture.** A flight simulator gives a pilot a real cockpit, with real instruments and real controls, bolted to the floor instead of a plane.
>
> **In Kubernetes,** kind is the simulator. Each node runs the real Kubernetes programs, but the "computer" under each node is a Docker container on your laptop, not a separate machine.

### Install the tools on a Mac

This book is written for a Mac with an Apple chip (M1, M2, M3 or later). To check yours, open the Apple menu and choose About This Mac: the line called Chip names it.

First, install Homebrew. Go to [brew.sh](https://brew.sh), copy the one command on its front page, paste it into your terminal and press Enter. It asks for your Mac password, and may also offer to install Apple's command line developer tools. Say yes: they include git and make.

Then use Homebrew to install Go, kubectl and jq:

```bash
brew install go kubectl jq
```

`brew install` downloads each tool and sets it up so you can run it from the terminal. Homebrew installs the newest Go, and the book needs Go 1.24 or later, so the newest one works.

Next, install kind yourself, at exactly version 0.30.0, so you run the version this book was tested with. Type these four commands one at a time:

```bash
curl -sSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.30.0/kind-darwin-arm64
chmod +x kind
sudo mv kind /usr/local/bin/kind
kind version
```

Here is what each one does.

1. `curl` downloads kind from its page on GitHub and saves it as a file called `kind`. The flags: `-s` hides curl's progress bar, `-S` still shows errors, `-L` follows the web site if it sends curl on to another address, and `-o kind` names the saved file. In the address, `darwin` means macOS, and `arm64` means Apple's chips.
2. `chmod +x kind` marks the downloaded file as a program you may run. A file that holds a ready-to-run program is called a binary.
3. `sudo mv kind /usr/local/bin/kind` moves the file into `/usr/local/bin`, a folder where the terminal looks for programs. `mv` moves a file. `sudo` runs the command as the computer's administrator, because that folder belongs to the administrator; it asks for your password.
4. `kind version` runs kind for the first time and prints its version. Check that it says `v0.30.0`.

Last, install your Docker app, start it, and give it at least 4 CPUs and 8 GB of memory, because all three nodes run inside it. In Docker Desktop, open Settings, then Resources. With Colima, start it with `colima start --cpu 4 --memory 8`. In OrbStack, check its settings for a memory limit.

### Install the tools on Linux or Windows

On Windows, first install WSL2 by following [Microsoft's guide](https://learn.microsoft.com/windows/wsl/install), then open the Linux terminal it gives you. From then on, type every command in this book into that Linux terminal, and follow the Linux steps.

On Linux, install each tool from its own instructions: [Go](https://go.dev/doc/install), [kubectl](https://kubernetes.io/docs/tasks/tools/), [jq](https://jqlang.org/download/), and Docker, either [Docker Engine](https://docs.docker.com/engine/install/) or Docker Desktop. git, curl and make come from your system's package manager, the app store of the terminal: `sudo apt install git curl make` on Ubuntu, for example.

Then install kind with the same four commands as on a Mac, with one change: in the address, replace `kind-darwin-arm64` with the name for your chip. To find your chip, run `uname -m`. If it prints `x86_64`, use `kind-linux-amd64`. If it prints `aarch64`, use `kind-linux-arm64`.

### Get the book's code

Now download this book's code with git, and move into its folder:

```bash
git clone https://github.com/aarora79/k8s-book.git
cd k8s-book
```

`git clone` downloads a full copy of the book's repository, or repo: the folder that holds all of its code, together with its history. It saves the copy in a new folder called `k8s-book`. `cd` stands for "change directory" (directory is another word for folder), and it moves your terminal into that folder. Run every later command from inside it, unless a chapter says otherwise.

### Create the cluster

Make sure your Docker app is running, then type:

```bash
make lab
make check
```

`make lab` asks kind to build the cluster described in [`lab/kind-config.yaml`](https://github.com/aarora79/k8s-book/blob/main/lab/kind-config.yaml). The first time, this takes a few minutes, because Docker has to download the node image: the packaged copy of every file a node needs, including all of the Kubernetes programs.

The file names that node image exactly, by its digest. A digest is a long code worked out from every byte of the image (a byte is the smallest unit of stored data), so any change to the image, however small, gives a different code. Because of the digest, every reader of this book runs exactly the same Kubernetes programs.

`make lab` then waits until every node says it is Ready, which means its kubelet reports that it can run pods. `make check` tests the tools and the cluster, and prints `ok` or `FAIL` for each test.

Now ask the cluster for its nodes:

```bash
kubectl get nodes
```

```text
NAME                STATUS   ROLES           AGE   VERSION
lab-control-plane   Ready    control-plane   60s   v1.34.0
lab-worker          Ready    <none>          45s   v1.34.0
lab-worker2         Ready    <none>          45s   v1.34.0
```

Read the columns from left to right. NAME is the node's name. STATUS says whether it is Ready. ROLES says `control-plane` for the node that runs the control plane, and `<none>` for a plain worker node. AGE is how long ago the node started. VERSION is the version of Kubernetes it runs.

## Where your code runs

kind runs each node as a Docker container. On a Mac there is one more layer. Containers depend on features of the Linux kernel, and macOS does not have them. So your Docker app runs a small Linux virtual machine: a pretend computer, made in software, running inside your Mac. That makes your nodes Linux containers, inside a Linux virtual machine, inside macOS.

You can step inside a node:

```bash
docker ps --format '{{.Names}}'
docker exec -it lab-worker bash
```

`docker ps` lists the running containers. The `--format '{{.Names}}'` flag tells it to print only their names, and you should see your three nodes. `docker exec` runs a command inside a container, here `bash`, a shell, inside `lab-worker`. The `-it` flags connect your keyboard and screen to that shell, so you can type in it. Your terminal is now inside the node.

Inside the node you are the root user, the administrator account of a Linux computer, allowed to do anything on it. Three programs on the node matter for this book:

- systemd is the Linux program that starts other programs when the computer boots (starts up), and starts them again if they stop.
- containerd is the program that runs containers.
- The kubelet from the map tells containerd what to run.

Try these commands inside the node:

```bash
uname -m                      # aarch64 on Apple Silicon
systemctl status kubelet --no-pager | head -5
crictl ps                     # the containers this node runs
exit
```

1. `uname -m` prints the chip type. `aarch64` is the name Linux uses for Apple's chips and other ARM chips. On most Windows and Linux PCs it prints `x86_64` instead.
2. `systemctl status kubelet` asks systemd whether the kubelet is running. `--no-pager` prints the answer straight to the screen, and `| head -5` keeps the first five lines.
3. `crictl` is a command-line tool for talking to containerd, and `crictl ps` lists the containers that containerd is running on this node.
4. `exit` leaves the node's shell. Your terminal is back on your laptop.

Chapters 1, 6 and 7 use features of the Linux kernel, so their programs have to run on Linux, inside a node. For those chapters, the Makefile turns your Go code into a binary for the node's chip, copies it into a node with `docker cp` (which copies a file into a container), and runs it there with `docker exec`.

Every other chapter runs your program straight on your laptop. kind makes the API server reachable at an address on your own laptop, and tells kubectl that address. Your programs use the same address, so they talk to the API server over the network, the same way kubectl does.

## Break it

Now break the cluster on purpose, and watch the control plane notice. Stop one node's container:

```bash
docker stop lab-worker2
kubectl get nodes -w
```

The `-w` flag tells kubectl to keep watching, and to print a new line each time a node changes. It keeps running, so leave it running in this window.

After about 50 seconds, `lab-worker2` turns `NotReady`. Notice that nothing told the control plane the node had died. So how did it find out?

> **Everyday picture.** A night guard calls the front desk every hour to say all is well. If the desk hears nothing for two hours, it sends someone to look; it does not wait for the guard to report a problem.
>
> **In Kubernetes,** the hourly call is a Lease, another kind of object: a small record that the kubelet on each node updates on a timer. A controller called the node lifecycle controller watches the Leases, and treats a Lease that stops changing as a node that has died.

Here are the real numbers. Each kubelet renews its node's Lease every 10 seconds. The node lifecycle controller waits 50 seconds after the last renewal, then changes the node's Ready status to Unknown, which kubectl shows as `NotReady`. When `lab-worker2` stopped, its Lease stopped changing, so about 50 seconds later the node turned `NotReady`. You write that renewal yourself in chapter 6.

Now bring the node back. Open a second terminal window (on a Mac, press Command and N in Terminal), move into the book's folder with `cd k8s-book`, and start the node again:

```bash
docker start lab-worker2
```

Watch the first window. The node returns to `Ready` as soon as its kubelet starts renewing the Lease again. Then press Ctrl+C in the first window to stop watching.

## Design notes

Why kind, and not a lighter tool? kind runs the same programs that a production cluster runs, meaning a cluster that serves real users. Each part on the map is a separate program, with its own name: the API server is `kube-apiserver`, the scheduler is `kube-scheduler`, and all of the built-in controllers run together inside one program, `kube-controller-manager`. Alongside them run etcd and, on every node, the kubelet. kind sets them all up with kubeadm, the standard tool for installing these programs and connecting them to each other.

That matters for this book, because every chapter compares your program with the real one. Some lighter tools save memory by replacing etcd with another database, or by joining the parts into one program. That would change behavior that the chapters measure. Chapter 2, for example, measures how long the API server keeps its record of recent changes, and that depends on etcd.

## Improving and expanding

1. Easy: add a third worker node. Open [`lab/kind-config.yaml`](https://github.com/aarora79/k8s-book/blob/main/lab/kind-config.yaml) in a text editor, copy the two lines that start a `- role: worker` entry, and paste them below the last one. Then delete the cluster with `make clean` and build it again with `make lab`. Chapter 5's scheduler has more choices to make with more nodes.
2. Easy: run `kubectl get --raw /api/v1/nodes | jq '.items[].status.nodeInfo'`. The `--raw` flag sends that exact path to the API server and prints the JSON it sends back, which lists every node. The jq filter then goes through each node in the list (`.items[]`) and keeps only `status.nodeInfo`, the facts each node reports about itself. Compare the three nodes.
3. Medium: in [`lab/kind-config.yaml`](https://github.com/aarora79/k8s-book/blob/main/lab/kind-config.yaml), the line `kubeProxyMode: iptables` tells kube-proxy how to write its kernel rules. iptables and nftables are two ways to write network rules into the Linux kernel, and nftables is the newer one. Change the line to `kubeProxyMode: nftables`, recreate the cluster, and run `docker exec lab-worker nft list ruleset | head -50`. `nft` is the tool that prints nftables rules, and this shows the first 50 lines of the rules kube-proxy wrote. Chapter 7 explains them.

## Further reading

- [kind quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes components](https://kubernetes.io/docs/concepts/overview/components/)
- [Kamal Marhubi, Kubernetes from the ground up](https://kamalmarhubi.com/blog/2015/09/06/kubernetes-from-the-ground-up-the-api-server), which starts the Kubernetes programs one at a time
