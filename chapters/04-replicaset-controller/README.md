# Chapter 4: A ReplicaSet controller

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

A controller for your own copy of a ReplicaSet: it counts pods that match a label selector and creates or deletes pods until the count matches `replicas`. This is the reconcile loop, the pattern every later chapter repeats.

## What the real one does

The real [ReplicaSet controller](https://github.com/kubernetes/kubernetes/blob/v1.34.0/pkg/controller/replicaset/replica_set.go) runs inside kube-controller-manager. It watches ReplicaSets and pods through shared informers, puts keys on a [rate-limited workqueue](https://github.com/kubernetes/kubernetes/blob/v1.34.0/staging/src/k8s.io/client-go/util/workqueue/rate_limiting_queue.go), and in each `syncReplicaSet` call compares desired and actual pods, then creates or deletes the difference in batches. It sets owner references so garbage collection removes pods when their ReplicaSet goes, and it tracks "expectations" so it does not act twice on writes its informer has not seen yet.

## Scope

| Supported | Left out |
| --- | --- |
| Reconcile by label count, create and delete | Pod templates beyond one container |
| Owner references, so deleting the owner deletes the pods | Adoption and orphaning of existing pods |
| A workqueue with retry and backoff | Expectations, slow-start batching |
| Pods that are terminating do not count | Status conditions |

## Build it (planned steps)

1. Version 1: a loop that lists pods every five seconds and fixes the count. It works, and it is wasteful.
2. Switch to client-go informers and a workqueue: react to events, keyed by object name.
3. Add owner references and show garbage collection deleting pods when the owner goes.
4. Handle terminating pods and conflicts (the `409` from chapter 2) by requeueing.

## Run it beside the real one

Your controller manages ReplicaSet-shaped objects labeled `controller: toy`; the real one ignores pods it does not own. Run both, delete pods, and watch each controller repair only its own.

## Break it

1. Kill the controller in the middle of a scale-up, change `replicas`, and restart it. Level-triggered logic converges anyway.
2. Remove the owner reference and delete the parent. The pods become orphans.

## Improving and expanding

1. Easy: report `status.readyReplicas`.
2. Medium: implement expectations and show the double-create they prevent.
3. Hard: write a Deployment controller on top that rolls between two ReplicaSets.

## Further reading

- [Kubernetes controllers](https://kubernetes.io/docs/concepts/architecture/controller/)
