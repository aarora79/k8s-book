# Chapter 5: A toy scheduler

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

A scheduler that runs beside the default one. It watches for pending pods whose `spec.schedulerName` is `toy`, filters nodes that have room, scores the rest with a rule you choose, and binds the pod to the winner.

## What the real one does

The real scheduler runs each pod through a framework of plugins: filter plugins remove nodes that cannot run the pod, score plugins rank the rest, and the bind step writes a Binding. The cycle lives in [schedule_one.go](https://github.com/kubernetes/kubernetes/blob/v1.34.0/pkg/scheduler/schedule_one.go). It keeps its own cache of what it has already placed, so it does not wait for the kubelet to confirm before scheduling the next pod.

## Scope

| Supported | Left out |
| --- | --- |
| Filter by allocatable CPU and memory minus requests | Affinity, taints, topology spread, volumes |
| One scoring rule of your own | Plugin framework, preemption |
| Binding through the `binding` subresource | Gang scheduling, scheduling queues with priorities |

## Build it (planned steps)

1. Watch pods with `schedulerName: toy` and no `nodeName`; bind each to the first node.
2. Filter: sum the requests of pods already on each node and drop nodes without room.
3. Score: pick a rule (least loaded, most loaded to pack, or a node label) and log the scores.
4. Keep an assumed-pod cache so two pods arriving together do not both land on a node that fits only one.

## Run it beside the real one

Create a Deployment with half its pods using `schedulerName: toy`. Both schedulers place pods on the same nodes; compare their choices.

## Break it

1. Remove the assumed-pod cache and create ten pods at once on a nearly full cluster.
2. Bind a pod to a node that does not exist and read the error.

## Improving and expanding

1. Easy: respect `nodeSelector`.
2. Medium: honor `NoSchedule` taints and tolerations.
3. Hard: implement simple preemption of lower-priority pods.

## Further reading

- [Scheduling framework](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/)
- [Writing your own scheduler with kube-scheduler-simulator](https://cncf.io/blog/2022/08/24/writing-your-own-scheduler-with-kube-scheduler-simulator)
