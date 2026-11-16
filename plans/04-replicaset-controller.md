# Plan: chapter 4, a ReplicaSet controller

Folder: `chapters/04-replicaset-controller/`. First chapter with dependencies: `k8s.io/client-go`, `k8s.io/api`, `k8s.io/apimachinery` at the version pinned in `STYLE.md`.

## Goal

The reconcile loop. The reader builds a controller for a ReplicaSet-shaped object and learns the pattern every later chapter reuses: watch, enqueue a key, read desired and actual state from the cache, act on the difference, requeue on error.

## Design decision

Do not fight the real ReplicaSet controller over real ReplicaSets. Use a ConfigMap as the "desired state" record until chapter 8 introduces CRDs: a ConfigMap labeled `toy.hmlk8s/kind=ToyReplicaSet` with data keys `replicas`, `selector` (label key=value) and `image`. The controller creates bare pods labeled with the selector plus `toy.hmlk8s/owner=<configmap-name>`. Say in the README why: a CRD is chapter 8's subject, and the real controller ignores pods it does not own, so the two never collide. Check that claim against `pkg/controller/replicaset/replica_set.go` at the pinned tag before writing it.

## Steps

1. **step1: polling.** Every 5 seconds list ToyReplicaSet ConfigMaps and their pods with plain client-go calls, create or delete pods to match. About 100 lines. It works and wastes API calls; the README counts them with `-v=6` logs or a request counter.
2. **step2: informers and a workqueue.** `SharedInformerFactory` for ConfigMaps (filtered by label) and pods; event handlers enqueue the owner key; `workqueue.NewTypedRateLimitingQueue`; worker goroutines call `sync(key)`. Point back to chapter 3: each client-go piece replaces something the reader built.
3. **step3: owner references.** Set `ownerReferences` on each pod pointing at the ConfigMap (`controller: true`, `blockOwnerDeletion: true`). Delete the ConfigMap and watch the garbage collector delete the pods.
4. **step4: correctness.** Ignore pods with a `deletionTimestamp` when counting; requeue with backoff on `409 Conflict`; write `status`-like fields (`readyReplicas`) back to the ConfigMap's annotations, retrying on conflict with `retry.RetryOnConflict`.
5. **step5 (optional): expectations.** Track pods created but not yet seen in the cache to avoid a double create on fast resyncs. Demonstrate the bug first by removing it under load (create a ToyReplicaSet with 50 replicas).

## Tests

- Create a ToyReplicaSet with 3 replicas: 3 pods Running within 60 seconds.
- Scale to 5, then to 1: pod count follows.
- Delete a pod: a replacement appears.
- Kill the controller, change replicas to 4, restart: converges to 4.
- Delete the ConfigMap: pods are garbage collected.
- Real ReplicaSets in `kube-system` are untouched (coredns pod count unchanged).

## README points

- Level-triggered versus edge-triggered: why the controller recomputes from current state instead of trusting events.
- Design notes: expectations, slow-start batch creation, and `burstReplicas` in the real controller, each linked to `replica_set.go` at the pinned tag.
- Run it beside the real one: a real ReplicaSet and a ToyReplicaSet with the same image; delete a pod from each and compare reaction time and events (`kubectl get events`).

## Check before writing

- The current typed workqueue API names in client-go v0.37 (`NewTypedRateLimitingQueue`, `TypedRateLimitingInterface`) and the recommended rate limiter constructor.
- That the garbage collector honors owner references from a ConfigMap owner to pods (it should; any namespaced owner in the same namespace works).

## Done when

- All steps build; tests pass on the lab and in CI; the README's sample outputs come from real runs.
