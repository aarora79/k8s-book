# Chapter 6: A toy kubelet

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

A node agent. It registers a Node object called `toy-node`, renews the node's Lease so the control plane knows it is alive, watches for pods bound to it, runs each pod's command with your chapter 1 runtime, and reports the pod's status. At the end of this chapter your controller creates a pod, your scheduler binds it and your kubelet runs it.

## What the real one does

The real [kubelet](https://github.com/kubernetes/kubernetes/blob/v1.34.0/pkg/kubelet/kubelet.go) syncs each pod through the container runtime over the Container Runtime Interface, sets up volumes and networking through plugins, runs probes, and reports status. A [lease controller](https://github.com/kubernetes/kubernetes/blob/v1.34.0/staging/src/k8s.io/component-helpers/apimachinery/lease/controller.go) renews the node's Lease in `kube-node-lease`; when renewals stop, the node lifecycle controller marks the node `NotReady` and later evicts its pods.

## Scope

| Supported | Left out |
| --- | --- |
| Register a Node with capacity, renew its Lease | Node status images, volumes, devices |
| Run each pod's first container with the chapter 1 runtime | Pod networking: pods share the node's network |
| Report `Pending`, `Running`, `Succeeded`, `Failed` | Probes, restarts with backoff |
| A `NoSchedule` taint so only test pods land here | Init containers, sidecars |

## Build it (planned steps)

1. Create the Node object and renew a Lease every 10 seconds; watch `kubectl get nodes` show `toy-node Ready`.
2. Watch pods with `spec.nodeName=toy-node` and print them.
3. Start each pod's command with `step4 run`, inside the lab-worker container, and record the process.
4. Report status through the `status` subresource, and clean up when the pod is deleted.
5. Chain it: a toy ReplicaSet (chapter 4) with `schedulerName: toy` (chapter 5) and a toleration for `toy-node`.

## Run it beside the real one

Run a pod on `lab-worker` (the real kubelet) and one on `toy-node` (yours), then compare `kubectl get pod -o yaml` for both, section by section.

## Break it

1. Stop your kubelet and time how long the node takes to go `NotReady`.
2. Run a pod whose command exits 1 and check the status you report.

## Improving and expanding

1. Easy: support `restartPolicy: Always` with a fixed delay.
2. Medium: run every container in the pod, not just the first.
3. Hard: give each pod a network namespace and a veth pair.

## Further reading

- [Nodes and node heartbeats](https://kubernetes.io/docs/concepts/architecture/nodes/)
- [Kamal Marhubi, What even is a kubelet?](https://kamalmarhubi.com/blog/2015/08/27/what-even-is-a-kubelet/)
