# Help me learn Kubernetes

Learn Kubernetes by rebuilding its parts.

Read it online at [aarora79.github.io/k8s-book](https://aarora79.github.io/k8s-book/).

Kubernetes is a system for running programs on a group of computers. You tell it what you want running, for example "three copies of this web server", and it starts the programs, places each one on a computer with room for it, and starts a program again if it stops. The group of computers is called a cluster.

Kubernetes itself is made of a handful of separate programs that work together. In this book you write your own small version of most of them, in the Go programming language. Each chapter builds one. You run it on a small practice cluster on your laptop, right beside the real program it copies. Then you read the real program's source code, the written instructions it was built from, to see where the two differ and why.

By the last chapter, your own programs do almost the whole job. One decides how many copies of a program should run, one picks a computer for each copy, one starts it, one sends network traffic to it, and one checks each new request before Kubernetes saves it. The one part you never replace is the API server, the hub that every other part talks to and that keeps the record of everything you asked for.

The shape of the book comes from Herbert Schildt's *Born to Code in C* (Osborne/McGraw-Hill, 1989). Schildt did not teach C one feature at a time. Each chapter built one complete, useful program, such as a text editor or an interpreter for a small language, and you learned C by building real things in it. This book does the same for Kubernetes.

## Who this is for

You want to know what happens inside Kubernetes, and you learn best by building. You do not need to have used Kubernetes, Linux or Go before. You type every instruction into a terminal, and chapter 0 shows you how. Every new term is explained the first time it appears, starting from an everyday example, and the [glossary](GLOSSARY.md) collects the book's terms in one place.

If you would like a gentler, step-by-step start first, the [archived 13-phase course](https://github.com/aarora79/k8s-100-to-mcp-gateway) goes from zero to a working cluster.

## How the book is laid out

Every chapter follows the same three beats.

1. You build your own small version of one part of Kubernetes, in Go.
2. You run it on your practice cluster, right beside the real part. You control both with the real Kubernetes tools: kubectl, the command-line tool you type Kubernetes commands into, and YAML files, plain-text files that describe what you want running. These are the same tools you would use at work. Then you compare what the two did.
3. You read the real part's source code, to see why it works differently from yours.

So you use real Kubernetes from the very first chapter. Your own version is never a replacement for learning the real one; it is how you come to understand it. When you watch your own scheduler (the part that picks a computer for each program) and the real one place the same programs, you learn what the real one does, and you also learn why.

The chapters fall into three parts.

- Chapters 0 to 6 build the pipeline that turns "please run this" into a running program. Chapter 0 sets up the practice cluster and draws a map of every part of Kubernetes. Chapter 1 builds a container, the walled-off space a program runs in. Chapter 2 talks to the API server by hand. Chapters 3 to 6 build a client for the API server, a controller (a program that keeps checking that what runs matches what you asked for), a scheduler, and a kubelet (the agent on each computer that starts the programs).
- Chapters 7 to 10 add what a real application needs: network traffic between programs, your own kinds of records, checks on every new or changed record, and a way in from outside the cluster. Two of these chapters go one step further. After you build your version, you rebuild it with the tool that real projects use, so you see how much work that tool does for you. Chapter 8 uses controller-runtime, the Go library most real controllers are built on. Chapter 9 uses CEL (Common Expression Language), a small rule language that the API server can run itself.
- Chapter 11 is the capstone, the final project. You run a real application on the parts you built: MCP Gateway Registry, an open-source program that connects AI assistants to the tools they use. Then you run the swap test: you replace your parts with the real ones, one at a time, and check after each swap that the application still works. When the last swap passes, you have shown that your parts do the same job as the real ones.

What the book leaves out is running large real-world applications the standard way: writing the YAML files for many programs at once (Deployments, Services, and Helm charts, which are bundles of such files), and the day-to-day care of a cluster that real users depend on. The [archived 13-phase course](https://github.com/aarora79/k8s-100-to-mcp-gateway) covers that ground, and after this book you will know what each of those YAML files asks Kubernetes to do.

## Chapters

Each chapter explains every word in its row. This table is a preview, so a word in it may not make sense until you reach that chapter.

| # | Chapter | You build | Status |
| --- | --- | --- | --- |
| 0 | [The map and the lab](chapters/00-map-and-lab/README.md) | A practice cluster on your laptop, built with kind (a tool that makes a whole cluster out of containers) and fixed to Kubernetes 1.34.0, plus one command, `make check`, that proves it works | Written |
| 1 | [A container by hand](chapters/01-container-by-hand/README.md) | A container runtime (the program that starts containers) in about 200 lines of Go, using the Linux features that give a program its own view of the computer (namespaces), its own files (chroot) and limits on what it may use (cgroups) | Written |
| 2 | [Talk to the API server with curl](chapters/02-api-server-with-curl/README.md) | Create, watch for changes to, change and delete programs, using only curl, a command-line tool that sends web requests | Written |
| 3 | [A mini kubectl and an informer](chapters/03-mini-kubectl-and-informer/README.md) | `kk`, your own small kubectl, and an informer, code that keeps an up-to-date local copy of the cluster's records, using only the code that comes with Go | Planned |
| 4 | [A ReplicaSet controller](chapters/04-replicaset-controller/README.md) | The check-and-fix loop that keeps a set number of copies of a program running | Planned |
| 5 | [A toy scheduler](chapters/05-toy-scheduler/README.md) | A scheduler that picks a computer for each program, running beside the real one | Planned |
| 6 | [A toy kubelet](chapters/06-toy-kubelet/README.md) | An agent for one computer in the cluster that runs programs with your chapter 1 runtime | Planned |
| 7 | [A Service by hand](chapters/07-service-by-hand/README.md) | A small kube-proxy, the program on each computer that keeps the network rules up to date, so one fixed address reaches a group of programs | Planned |
| 8 | [A CRD and an operator](chapters/08-crd-and-operator/README.md) | Your own kind of record (a CRD, custom resource definition) and an operator, a controller that runs one application, then the same with controller-runtime | Planned |
| 9 | [An admission webhook](chapters/09-admission-webhook/README.md) | A webhook, a small web server the API server asks before it saves a record; one kind refuses records, the other changes them. Then the same rule in CEL | Planned |
| 10 | [A tiny gateway](chapters/10-tiny-gateway/README.md) | A front door for traffic from outside the cluster, which reads routing rules from Kubernetes and passes each request to the right program | Planned |
| 11 | [Capstone: MCP Gateway Registry](chapters/11-capstone-mcp-gateway/README.md) | MCP Gateway Registry running on your parts, then the swap test | Planned |

## How each chapter works

Every chapter folder has the same layout:

```text
chapters/04-replicaset-controller/
  README.md          the chapter text
  step1/ step2/ ...  complete, runnable code after each step
  test.sh            the chapter's tests
  Makefile           make run, make test
  ERRATA.md          fixes readers report
```

The Makefile is a file of named commands for the make tool, which chapter 0 explains. ERRATA is a list of corrections that readers send in.

Step 1 is always the smallest version that works from start to finish. Each later step adds one idea. So if you compare the `step2` folder with the `step3` folder, the only difference is that one idea.

Every chapter has the same sections, in the same order: what you will build, what the real one does, scope, set up, build it, run it beside the real one, break it, design notes, improving and expanding, and further reading.

## Requirements

- A Mac with an Apple chip (M1 or later), or a Linux computer. A Windows computer works too, through WSL2 (Windows Subsystem for Linux 2, which runs Linux inside Windows).
- An app that runs containers: Docker (Docker Desktop, OrbStack or Colima on a Mac) or Podman.
- These command-line tools: git, Go 1.24 or later, kind 0.30.0, kubectl, curl, jq and make, plus Homebrew to install them on a Mac.

Chapter 0 explains what each of these tools does, walks you through installing them, and checks every version.

## Running the tests

Open a terminal (the window where you type commands), move into the book's top folder, and type:

```bash
make lab     # create the kind cluster
make check   # confirm the lab works
make test    # run every written chapter's tests against the cluster
make clean   # delete the cluster
```

The book's rule is that every code sample is copied from a program that runs, and every sample output comes from a real run. The tests above check that the code still runs.

## Style

See [STYLE.md](STYLE.md) for the writing and code rules.

## Archive

The earlier course, *Kubernetes from 100 to MCP Gateway*, lives in its own repository (a project's folder of files on GitHub), [k8s-100-to-mcp-gateway](https://github.com/aarora79/k8s-100-to-mcp-gateway). It has 13 hands-on phases and two capstones: MCP Gateway Registry, and Gemma (an AI model from Google) running on the cluster, with Prometheus and Grafana (tools that collect and chart measurements).

## License

The [Apache License 2.0](LICENSE) covers the book text and code.
