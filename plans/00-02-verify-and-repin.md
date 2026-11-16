# Plan: verify chapters 0 to 2 and move the version pins

Chapters 0 to 2 are written but have never run on a kind cluster. The code was tested on a plain Linux host (chapter 1, cgroup v1) and against a k3s 1.34 API server (chapter 2). This session makes them pass on the real lab, on an Apple Silicon Mac and in CI, and moves the pins off an end-of-life Kubernetes release.

## Verified facts (2026-11-16)

- Kubernetes 1.34 reached end of life in late October 2026. 1.37.0 was released on 2026-08-26 and is supported until 2027-10-28.
- kind v0.33.0 ships `kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5` as its default node image.
- kube-proxy's nftables mode has been GA since 1.33; iptables is still the default mode.
- MutatingAdmissionPolicy was beta in 1.34; one source reports it GA in 1.36 (check before chapter 9 relies on it).

## Check before writing

- The latest kind release and its default 1.37 node image digest, from the kind GitHub releases page. Use the newest patch image of 1.37 that kind publishes.
- The Go version to pin. Go 1.24 is past upstream support. Use the newest stable Go that the k8s.io v0.37 modules accept, and update `go.mod`, `STYLE.md`, chapter headers and `.github/workflows/ci.yml` together.
- The client-go and controller-runtime versions that match Kubernetes 1.37 (client-go `v0.37.x`; controller-runtime publishes one minor per client-go minor). Record them in `STYLE.md` for chapters 3 onward.

## Tasks

1. Repin. Update `lab/kind-config.yaml` (all three node images), `lab/check.sh` (`WANT_K8S` and the kind version case), `STYLE.md` (versions table), the top-level `README.md` (chapter 0 row, requirements), `chapters/00-map-and-lab/README.md` (header, install URL, sample outputs) and the `Written for` line of chapters 0 to 2.
2. Run `make lab` and `make check` on the Mac. Fix `check.sh` until it reports every check correctly. Paste the real `make check` and `kubectl get nodes` output into chapter 0.
3. Chapter 0 "Where your code runs" and "Break it": run every command. Confirm `crictl ps` works in the node, confirm the `uname -m` output, time how long `lab-worker2` takes to turn `NotReady`, and correct the text if any claim is wrong.
4. Chapter 1 on cgroup v2. Run `make -C chapters/01-container-by-hand test`. The cgroup v2 branch of `step4/main.go` has never run. Expected risks:
   - `pids.max` missing in the new cgroup because the node's root `cgroup.subtree_control` lacks `pids` or `memory`. Inspect it with `docker exec lab-worker cat /sys/fs/cgroup/cgroup.subtree_control`. If the controllers are missing, create the cgroup under a delegated subtree instead, and explain the choice in the README.
   - Writing `0` to `cgroup.procs` from the child. It should move the writer; confirm.
   - `memory.swap.max` absent: the code already skips missing optional files; confirm the memory test still gives exit 137.
   - The busybox export lacking `/proc` or `/dev`: `mountDev` creates `/dev`; check `/proc`.
5. Chapter 1 README: rerun every command shown, including "Run it beside the real one" and all three "Break it" items, and replace each sample output with the real one. Check the claim about which namespaces a pod's process has, and where its cgroup sits.
6. Chapter 2 on kind: run `make -C chapters/02-api-server-with-curl test`, then each step by hand. Replace sample outputs with real ones. Known difference: unauthenticated requests get `403` for `system:anonymous` on kubeadm clusters; the README already says so, confirm it. In step 3 the pod really runs on kind, so the event list is longer than on k3s; show the real list and keep the explanation in line with it.
7. CI: push the branch and make the `static` and `chapters` jobs pass on GitHub. The runner is cgroup v2, so it is a second check of chapter 1.
8. Update the chapter 7 and 9 plan READMEs if the 1.37 facts change them (for example MutatingAdmissionPolicy moving from "Left out" to "Supported" if it is GA in 1.37).

## Done when

- `make lab && make check && make test` passes on the Mac and in CI.
- No sample output in chapters 0 to 2 comes from anywhere but the 1.37 lab.
- `STYLE.md` lists the pinned Kubernetes, kind, Go, client-go and controller-runtime versions.

## Sources

- [Kubernetes 1.37 release page](https://kubernetes.io/releases/1.37/)
- [kind releases](https://github.com/kubernetes-sigs/kind/releases)
- [Kubernetes blog: NFTables mode for kube-proxy](https://kubernetes.io/blog/2025/02/28/nftables-kube-proxy/)
- [Mutating Admission Policy docs (1.34, beta)](https://v1-34.docs.kubernetes.io/docs/reference/access-authn-authz/mutating-admission-policy/)
