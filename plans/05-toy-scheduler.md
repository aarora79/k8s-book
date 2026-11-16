# Plan: chapter 5, a toy scheduler

Folder: `chapters/05-toy-scheduler/`. Uses client-go.

## Goal

A scheduler that runs beside the default one and places only pods with `spec.schedulerName: toy`. The reader sees that scheduling is a controller whose only write is a Binding.

## Steps

1. **step1: bind to the first node.** Informer on pods with field selector `spec.schedulerName=toy,spec.nodeName=` (check that both field selectors are supported for pods). For each pending pod, `POST` a `Binding` to `pods/<name>/binding` naming the first Ready node. About 100 lines.
2. **step2: filter.** Compute each node's free CPU and memory as `status.allocatable` minus the sum of container requests of non-terminal pods on that node (from a pod informer indexed by `spec.nodeName`). Drop nodes without room, nodes that are not Ready and nodes with `NoSchedule` taints the pod does not tolerate. If no node fits, record an Event on the pod with reason `FailedScheduling`, like the real scheduler.
3. **step3: score.** A pluggable `Score(pod, node) int` with two built-ins selectable by flag: least-allocated (spread) and most-allocated (pack). Log the scores for each decision so the reader can follow it.
4. **step4: the assumed cache.** After a successful bind, add the pod's requests to the node's usage in memory immediately, before the informer sees the update. Show the double-booking bug without it: on a nearly full node, create ten pods at once.

## Tests

- A pod with `schedulerName: toy` gets bound; a pod without it is bound by the default scheduler, not by the toy one (check the `Scheduled` event's reporting component).
- A pod requesting more CPU than any node has stays Pending with a `FailedScheduling` event from `toy`.
- `-score=pack` puts consecutive pods on the same node; `-score=spread` alternates.
- Assumed cache: ten pods each requesting a third of a node's free CPU never exceed capacity.

## README points

- The real scheduler's cycle in `pkg/scheduler/schedule_one.go`: scheduling cycle then binding cycle, plugin extension points (PreFilter, Filter, Score, Reserve, Permit, Bind), and the scheduling queue with backoff. Link at the pinned tag.
- Why the real scheduler assumes pods in its cache and binds asynchronously.
- Run it beside the real one: one Deployment with half its pods on each scheduler; compare placements and the time from creation to binding.
- Break it: bind to a node that does not exist and read the error; delete the assumed cache.

## Check before writing

- Field selector support for `spec.schedulerName` on pods in 1.37.
- The Binding subresource's current form (`v1.Binding` posted to `pods/{name}/binding`) and which component name the Events should carry.

## Done when

- Tests pass on the lab and in CI; outputs in the README are real.
