# Chapter 0: The map and the lab

Written for Kubernetes 1.34.0, kind 0.30.0, Go 1.24.

## What you will build

A three-node Kubernetes cluster on your laptop, pinned to the exact version the book's tests use, and a check that proves it works. On an Apple Silicon Mac, `make check` ends like this:

```text
Cluster
  ok    kind cluster 'lab' exists
  ok    API server is v1.34.0
  ok    3 of 3 nodes Ready
  ok    can run commands inside lab-worker (arch aarch64)

The lab is ready.
```

Before the lab, this chapter draws the map: the parts of Kubernetes, how they talk to each other, and which chapter rebuilds each one.

## The map

Kubernetes has one hub. The API server is the only component that reads and writes the cluster's database, etcd. Every other component, including kubectl, talks only to the API server. None of them call each other.

> **Everyday picture.** In a restaurant kitchen, the waiter clips each order ticket to a rail above the counter. The cooks never talk to the waiter or to each other. Each cook reads the rail, takes the tickets for their station and marks them done, and the stack of tickets is the only record of what the kitchen owes. **In Kubernetes,** the API server is the rail, etcd is the stack of tickets it keeps, and each component is a cook that watches for its own kind of ticket.

![The map: kubectl sends requests to the API server; the API server alone talks to etcd and calls admission webhooks; controllers, scheduler, kubelet, kube-proxy and gateway all watch the API server.](images/map.svg)

> **Everyday picture.** A thermostat holds a target temperature. It reads the room, compares it with the target and turns the heating on or off to close the gap. It does not care how the room got cold, and it keeps checking after the room is warm. **In Kubernetes,** an object's spec is the target (the desired state), what is running is the room (the actual state), and a program that closes the gap in a loop is a controller.

Each component runs the same pattern. It watches the API server for objects it cares about, compares what the objects ask for with what exists, and acts to close the gap. It then writes what it did back to the API server, where the next component sees it.

Follow one Deployment from `kubectl apply` to a running process:

1. kubectl sends the Deployment to the API server, which stores it in etcd. You do this with curl in chapter 2.
2. The Deployment controller creates a ReplicaSet. The ReplicaSet controller sees that it wants three pods and finds none, so it creates three Pod objects. You build this loop in chapter 4.
3. The scheduler sees three pods with no node. For each one it picks a node and writes a Binding. You build a scheduler in chapter 5.
4. The kubelet on the chosen node sees a pod bound to it and starts its containers. You build a kubelet in chapter 6, using the container runtime from chapter 1.
5. kube-proxy sees the pods behind a Service and writes kernel rules so the Service's address reaches them. You build this in chapter 7.

No step calls the next one. Each component writes to the API server and the next one notices. That is why you can replace any one of them with your own program, which is what this book does.

## Scope

| Supported | Left out |
| --- | --- |
| One cluster on one laptop, three nodes | High availability, multiple control-plane nodes |
| Kubernetes 1.34.0 through kind 0.30.0 | Other versions, other local tools (minikube, k3d) |
| Apple Silicon Macs, Linux, Windows through WSL2 | Cloud clusters |

## Set up

### Install the tools

On a Mac with Homebrew:

```bash
brew install go kubectl jq
```

Install kind 0.30.0 itself, so the version matches the book:

```bash
curl -sSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.30.0/kind-darwin-arm64
chmod +x kind
sudo mv kind /usr/local/bin/kind
kind version
```

On Linux, use `kind-linux-amd64` or `kind-linux-arm64` in the URL.

You also need a Docker runtime: Docker Desktop, OrbStack or Colima. Give it at least 4 CPUs and 8 GB of memory.

### Create the cluster

From the repo root:

```bash
make lab
make check
```

`make lab` runs `kind create cluster --config lab/kind-config.yaml` and waits for every node to report Ready. The config pins the node image by digest, so everyone runs the same Kubernetes binaries.

```bash
kubectl get nodes
```

```text
NAME                STATUS   ROLES           AGE   VERSION
lab-control-plane   Ready    control-plane   60s   v1.34.0
lab-worker          Ready    <none>          45s   v1.34.0
lab-worker2         Ready    <none>          45s   v1.34.0
```

## Where your code runs

> **Everyday picture.** A flight simulator gives a pilot a real cockpit, with real instruments and real controls, bolted to the floor instead of a plane. **In Kubernetes,** kind is the simulator: each node (one machine in the cluster) runs the real Kubernetes programs, but the machine under them is a Docker container on your laptop.

kind runs each Kubernetes node as a Docker container. On a Mac, Docker itself runs inside a small Linux virtual machine, so the nodes are Linux containers inside a Linux VM inside macOS.

```bash
docker ps --format '{{.Names}}'
docker exec -it lab-worker bash
```

Inside the node you are root on a Linux machine with systemd, containerd and a kubelet:

```bash
uname -m                      # aarch64 on Apple Silicon
systemctl status kubelet --no-pager | head -5
crictl ps                     # the containers this node runs
exit
```

Chapters 1, 6 and 7 need Linux kernel features: namespaces, cgroups and netfilter. Their Makefiles build your Go program for the node's architecture, copy it into a node with `docker cp`, and run it there with `docker exec`. Every other chapter runs your program on the Mac and talks to the API server over the network, the same way kubectl does.

## Break it

Stop one node and watch the control plane notice:

```bash
docker stop lab-worker2
kubectl get nodes -w
```

Within about a minute, `lab-worker2` turns `NotReady`. Nothing told the control plane the node died.

> **Everyday picture.** A night guard calls the front desk every hour to say all is well. If the desk hears nothing for two hours, it sends someone to look; it does not wait for the guard to report a problem. **In Kubernetes,** the call is a Lease: a small object that the kubelet (the agent on each node) updates on a timer, and the node lifecycle controller treats a Lease that stops changing as a dead node.

The kubelet on each node renews a Lease object every few seconds, and the node lifecycle controller marks a node `NotReady` when its Lease goes stale. You will write that renewal yourself in chapter 6.

```bash
docker start lab-worker2
```

The node returns to `Ready` once its kubelet renews the Lease again.

## Design notes

kind runs the same binaries that production clusters run: kube-apiserver, etcd, kube-scheduler, kube-controller-manager and the kubelet, set up by kubeadm. That matters for this book, because every chapter compares your program with the real one. Tools that swap etcd for SQLite or merge the components into one process would change behavior the chapters depend on, such as how long a watch can resume.

## Improving and expanding

1. Easy: add a third worker to `lab/kind-config.yaml` and recreate the cluster. Chapter 5's scheduler gets more interesting with more nodes.
2. Easy: run `kubectl get --raw /api/v1/nodes | jq '.items[].status.nodeInfo'` and compare what each node reports about itself.
3. Medium: change `kubeProxyMode` to `nftables`, recreate the cluster, and run `docker exec lab-worker nft list ruleset | head -50`. Chapter 7 returns to this.

## Further reading

- [kind quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes components](https://kubernetes.io/docs/concepts/overview/components/)
- [Kamal Marhubi, Kubernetes from the ground up](https://kamalmarhubi.com/blog/2015/09/06/kubernetes-from-the-ground-up-the-api-server), which starts the components one at a time
