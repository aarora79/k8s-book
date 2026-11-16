# Help me learn Kubernetes

Learn Kubernetes by rebuilding its parts.

Read it online at [aarora79.github.io/k8s-book](https://aarora79.github.io/k8s-book/).

Each chapter builds one small, working piece of Kubernetes in Go, runs it against a real cluster on your laptop next to the real component, and then reads the real source to explain why Kubernetes does it differently. By the last chapter, a pod on your cluster was created by your controller, placed by your scheduler, run by your kubelet, reached through your Service rules and checked by your admission webhook.

The shape of the book comes from Herbert Schildt's *Born to Code in C* (Osborne/McGraw-Hill, 1989). Schildt did not teach C from the ground up. He assumed you knew the basics and spent each chapter building one complete, useful program: a C interpreter, a text editor, a multitasking kernel. You learned the language by building real things in it. This repo does the same for Kubernetes.

## Who this is for

You have used Kubernetes a little: you can apply a manifest and read `kubectl get pods`. You can read Go, or you are willing to learn it as you go. You want to know what happens between `kubectl apply` and a running process, and you learn best by building.

If you have never run a container, start with the [archived 13-phase course](archive/README.md), which goes from zero to a working cluster.

## Chapters

| # | Chapter | You build | Status |
| --- | --- | --- | --- |
| 0 | [The map and the lab](chapters/00-map-and-lab/README.md) | A kind cluster pinned to Kubernetes 1.34 and a `make check` that proves it works | Written |
| 1 | [A container by hand](chapters/01-container-by-hand/README.md) | A container runtime in about 150 lines of Go: namespaces, chroot, cgroups | Written |
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

Chapters 1 to 6 build a pod pipeline from your own parts. Chapters 7 to 10 add what a real application needs. Chapter 11 runs a real application on all of it.

## How each chapter works

Every chapter folder has the same layout:

```text
chapters/04-replicaset-controller/
  README.md          the chapter text
  step1/ step2/ ...  complete, runnable code after each step
  Makefile           make run, make test
  ERRATA.md          fixes readers report
```

Step 1 is always the smallest version that runs end to end. Each later step adds one idea, so you can diff `step2` against `step3` and see exactly what changed. The README sections are always the same: what you will build, what the real one does, scope, set up, build it, run it beside the real one, break it, design notes, improving and expanding, further reading.

## Requirements

- A Mac with Apple Silicon (the book is written and tested for it), or Linux. Windows works through WSL2.
- A Docker runtime: Docker Desktop, OrbStack or Colima.
- Go 1.24 or later, kind 0.30.0, kubectl, curl and jq.

Chapter 0 walks through the install and checks every version.

## Running the tests

```bash
make lab     # create the kind cluster
make check   # confirm the lab works
make test    # run every written chapter's tests against the cluster
make clean   # delete the cluster
```

CI runs the same targets on every push. A listing that does not run does not merge.

## Style

See [STYLE.md](STYLE.md) for the writing and code rules.

## Archive

The earlier course, *Kubernetes from 100 to MCP Gateway*, lives in [archive/](archive/). It has 13 hands-on phases and two capstones: MCP Gateway Registry, and Gemma served with Prometheus and Grafana. Git history for those files is intact.

## License

The book text and code are licensed under the [Apache License 2.0](LICENSE).
