# Help me learn Kubernetes

Learn Kubernetes by rebuilding its parts.

Read it online at [aarora79.github.io/k8s-book](https://aarora79.github.io/k8s-book/).

Kubernetes is made of a handful of separate programs that work together. In this book you write your own small version of each one, in the Go programming language. Each chapter builds one of them. You run it on a small Kubernetes cluster on your laptop, right beside the real program it copies. Then you read the real program's source code, to see where the two differ and why.

By the last chapter, your own programs do the whole job. One decides how many copies of a program should run, one picks a machine for each copy, one starts it, one sends network traffic to it, and one checks it before it is allowed in.

The shape of the book comes from Herbert Schildt's *Born to Code in C* (Osborne/McGraw-Hill, 1989). Schildt did not teach C one feature at a time. Each chapter built one complete, useful program, such as a text editor or a small operating system, and you learned the language by building real things in it. This book does the same for Kubernetes.

## Who this is for

You want to know what happens inside Kubernetes, and you learn best by building. You can read a little code in some language, and you are willing to pick up Go as you go. You do not need to have used Kubernetes before, though it helps. Every new term is explained the first time it appears, starting from an everyday example.

If you would like a gentler, step-by-step start first, the [archived 13-phase course](https://github.com/aarora79/k8s-100-to-mcp-gateway) goes from zero to a working cluster.

## How the book is laid out

Every chapter follows the same three beats.

1. You build your own small version of one part of Kubernetes, in Go.
2. You run it on your laptop cluster, right beside the real part, and use the real Kubernetes tools to drive both: kubectl commands and YAML files, the same ones you would use at work. Then you compare what the two did.
3. You read the real part's source code, to see why it works differently from yours.

So you use real Kubernetes from the very first chapter. Your own version is never a replacement for learning the real one; it is how you come to understand it. When you watch your toy scheduler and the real scheduler place the same pods, you learn what the real one does, and you also learn why.

The chapters fall into three parts.

- Chapters 0 to 6 build the pod pipeline. Chapter 0 sets up the lab and draws a map of Kubernetes. Chapters 1 to 6 then build, one part per chapter, everything that turns "please run this" into a running program: a container runtime, a client for the API server, a controller, a scheduler and a kubelet.
- Chapters 7 to 10 add what a real application needs: network traffic between pods, your own kinds of objects, checks on every new object, and a way in from outside the cluster. Two of these chapters go one step further. After you build your version, you rebuild it with the tool that real projects use, so you see how much work that tool does for you. Chapter 8 does this with controller-runtime, and chapter 9 with CEL.
- Chapter 11 is the capstone. You run a real application, MCP Gateway Registry, on the parts you built. Then you run the swap test: you replace your parts with the real ones, one at a time, and check after each swap that the application still works. When the last swap passes, you have shown that your parts do the same job as the real ones.

What the book leaves out is running large real-world applications the standard way: writing Deployments, Services and Helm charts for many programs, and the day-to-day care of a production cluster. The [archived 13-phase course](https://github.com/aarora79/k8s-100-to-mcp-gateway) covers that ground, and after this book you will know what each of those YAML files asks Kubernetes to do.

## Chapters

| # | Chapter | You build | Status |
| --- | --- | --- | --- |
| 0 | [The map and the lab](chapters/00-map-and-lab/README.md) | A kind cluster pinned to Kubernetes 1.34 and a `make check` that proves it works | Written |
| 1 | [A container by hand](chapters/01-container-by-hand/README.md) | A container runtime in about 200 lines of Go: namespaces, chroot, cgroups | Written |
| 2 | [Talk to the API server with curl](chapters/02-api-server-with-curl/README.md) | Create, watch, patch and delete pods with nothing but curl | Written |
| 3 | [A mini kubectl and an informer](chapters/03-mini-kubectl-and-informer/README.md) | `kk get`, `kk apply`, `kk watch` and a hand-built informer, standard library only | Planned |
| 4 | [A ReplicaSet controller](chapters/04-replicaset-controller/README.md) | The reconcile loop | Planned |
| 5 | [A toy scheduler](chapters/05-toy-scheduler/README.md) | A scheduler that runs beside the default one | Planned |
| 6 | [A toy kubelet](chapters/06-toy-kubelet/README.md) | A node agent that runs pods with your chapter 1 runtime | Planned |
| 7 | [A Service by hand](chapters/07-service-by-hand/README.md) | A small kube-proxy that writes iptables rules | Planned |
| 8 | [A CRD and an operator](chapters/08-crd-and-operator/README.md) | An `McpServer` resource and its controller, then the same with controller-runtime | Planned |
| 9 | [An admission webhook](chapters/09-admission-webhook/README.md) | A validating and a mutating webhook, then the same rule in CEL | Planned |
| 10 | [A tiny gateway](chapters/10-tiny-gateway/README.md) | A Gateway API HTTPRoute controller and reverse proxy | Planned |
| 11 | [Capstone: MCP Gateway Registry](chapters/11-capstone-mcp-gateway/README.md) | MCP Gateway Registry running on your parts, then the swap test | Planned |

The [glossary](GLOSSARY.md) at the end defines every term the book uses, each with an everyday example.

## How each chapter works

Every chapter folder has the same layout:

```text
chapters/04-replicaset-controller/
  README.md          the chapter text
  step1/ step2/ ...  complete, runnable code after each step
  Makefile           make run, make test
  ERRATA.md          fixes readers report
```

Step 1 is always the smallest version that works from start to finish. Each later step adds one idea. So if you compare the `step2` folder with the `step3` folder, the only difference is that one idea.

Every chapter has the same sections, in the same order: what you will build, what the real one does, scope, set up, build it, run it beside the real one, break it, design notes, improving and expanding, and further reading.

## Requirements

- A Mac with Apple Silicon (the book's main target), or Linux. Windows works through WSL2.
- A Docker runtime: Docker Desktop, OrbStack or Colima.
- Go 1.24 or later, kind 0.30.0, kubectl, curl and jq.

Chapter 0 explains what each of these tools does, walks you through installing them, and checks every version.

## Running the tests

```bash
make lab     # create the kind cluster
make check   # confirm the lab works
make test    # run every written chapter's tests against the cluster
make clean   # delete the cluster
```

Every code sample in the book is copied from a program that runs, and every sample output comes from a real run. The tests above check that this stays true.

## Style

See [STYLE.md](STYLE.md) for the writing and code rules.

## Archive

The earlier course, *Kubernetes from 100 to MCP Gateway*, lives in its own repo, [k8s-100-to-mcp-gateway](https://github.com/aarora79/k8s-100-to-mcp-gateway). It has 13 hands-on phases and two capstones: MCP Gateway Registry, and Gemma served with Prometheus and Grafana.

## License

The [Apache License 2.0](LICENSE) covers the book text and code.
