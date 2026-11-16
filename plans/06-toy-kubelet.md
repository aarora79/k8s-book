# Plan: chapter 6, a toy kubelet

Folder: `chapters/06-toy-kubelet/`. Uses client-go. Runs inside the `lab-worker` container, like chapter 1, because it starts processes with the chapter 1 runtime.

## Goal

A node agent that closes the loop. After this chapter a pod is created by the reader's controller (chapter 4), bound by their scheduler (chapter 5) and run by their kubelet.

## Design decisions

- The toy kubelet registers a Node named `toy-node`. It runs inside `lab-worker`, so its pods are processes in that container started with chapter 1's `step4` runtime and a busybox root filesystem.
- The node gets the taint `toy.hmlk8s/node=true:NoSchedule`, so only pods that tolerate it land there. The default scheduler may still place tolerating pods there; pods meant for it also set `schedulerName: toy` or `nodeName: toy-node`.
- Images: the toy kubelet does not pull images. It supports one image, `busybox`, mapped to the existing rootfs, and fails other images with a clear `ImagePullBackOff`-style status reason. Say so in Scope.
- Networking: pods share the node's network. The pod IP reported is the node's IP. Say so in Scope.
- Credentials: run with a kubeconfig copied into the node (the Makefile copies the kind admin kubeconfig rewritten to the in-cluster API address). Note in design notes that the real kubelet uses its own node identity and the Node authorizer.

## Steps

1. **step1: register and heartbeat.** Create the Node with capacity (`cpu: 2`, `memory: 2Gi`, `pods: 10`), set a `Ready` condition, and renew a Lease in `kube-node-lease` every 10 seconds. `kubectl get nodes` shows `toy-node Ready`. About 100 lines.
2. **step2: see bound pods.** Informer on pods with field selector `spec.nodeName=toy-node`; print adds and deletes.
3. **step3: run them.** For each new pod, start `step4 run -pids N -memory-mb M /root/rootfs <command...>` with limits from the first container's resources; keep the `exec.Cmd` in a map keyed by pod UID.
4. **step4: report status.** Update the pod's `status` subresource: `Pending` until the process starts, `Running` with `startTime` and a container status, then `Succeeded` or `Failed` with the exit code. Kill the process group when the pod is deleted, then remove the pod with a zero grace period, as the real kubelet confirms deletion.
5. **step5: the full chain.** A walkthrough, not new code: a ToyReplicaSet (chapter 4) whose pod template sets `schedulerName: toy` and the toleration; the chapter 5 scheduler binds to `toy-node`; this kubelet runs them. The README shows every event in order.

## Tests

- `toy-node` turns Ready within 20 seconds of start, and `NotReady` within about a minute of stopping the agent (check the node monitor grace period for 1.37 and use it).
- A pod with `nodeName: toy-node` and command `sh -c 'echo hi; sleep 2'` reaches `Succeeded`.
- A pod whose command exits 3 reaches `Failed` with exit code 3 in its container status.
- Deleting a running pod kills its process and the object disappears.
- The chain test from step 5 runs three pods end to end.

## README points

- The real kubelet's sync loop, CRI, the pod lifecycle, and the lease controller, linked at the pinned tag (`pkg/kubelet/kubelet.go`, `staging/src/k8s.io/component-helpers/apimachinery/lease/controller.go`).
- The node lifecycle controller: what marks a node `NotReady` and what taints it adds.
- Run it beside the real one: one pod on `lab-worker`, one on `toy-node`; diff `kubectl get pod -o yaml` section by section.
- Break it: stop the agent and watch the node lifecycle controller react; run a pod with an unsupported image.

## Check before writing

- Node monitor grace period and lease duration defaults in 1.37.
- Which status fields the API server accepts from a kubelet-like client through the `status` subresource, and whether the NodeRestriction admission plugin affects an admin-credential client (it should not).

## Done when

- Tests pass on the lab and in CI, including the chain test.
