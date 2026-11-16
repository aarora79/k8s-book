# Plan: chapter 7, a Service by hand

Folder: `chapters/07-service-by-hand/`. Uses client-go. Runs inside a kind node because it writes netfilter rules.

## Goal

A small kube-proxy that makes a ClusterIP reach pods, so the reader sees that a Service is a set of kernel rules written by a controller.

## Design decisions

- Avoid fighting the real kube-proxy. kube-proxy skips any Service that carries the label `service.kubernetes.io/service-proxy-name`, which exists so other proxies can own those Services (check that this holds in 1.37). The toy proxy handles only Services with `service.kubernetes.io/service-proxy-name: toy`, so each keeps a real ClusterIP that nothing else programs. It writes rules in its own chain, `TOY-SERVICES`, jumped to from `PREROUTING` and `OUTPUT` in the `nat` table.
- Fallback if the label does not work: headless Services plus an annotation `toy.hmlk8s/vip` holding an address outside the Service CIDR.
- The lab's `kubeProxyMode` is `iptables` so the reader can read the real chains next to theirs.

## Steps

1. **step1: read the real rules.** No code. `docker exec lab-worker iptables-save -t nat | grep KUBE`, then trace one Service from `KUBE-SERVICES` through `KUBE-SVC-*` to `KUBE-SEP-*` and the DNAT. The chapter text walks the chain for a Service the reader creates.
2. **step2: one rule by hand.** A shell script that adds a DNAT rule for a made-up VIP to one pod IP and curls it from the node.
3. **step3: the controller.** Watch Services (filtered) and EndpointSlices (by `kubernetes.io/service-name` label); on any change, rebuild `TOY-SERVICES` and per-service chains with `iptables-restore --noflush` in one transaction. About 150 lines.
4. **step4: even spread.** For N ready endpoints, use `-m statistic --mode random --probability 1/(N-i)` on rule i, the same trick kube-proxy uses. Measure the spread with 300 curls.
5. **step5: nftables.** Write the same mapping as an nftables table with a verdict map, applied with `nft -f`. Compare rule counts for 100 fake Services between the two versions.

## Tests

- A Service handled by the toy proxy answers from the node with the backend pod's hostname.
- Scaling the backend from 1 to 3 spreads 300 requests across all 3 (each between 20 and 46 percent).
- Scaling to 0 makes requests fail fast (decide REJECT versus no rule, and test what the README says).
- Cleanup removes every `TOY-` chain and the nft table.

## README points

- The real proxier files for iptables and nftables at the pinned tag; why nftables uses maps; that IPVS mode is deprecated (check the release).
- conntrack: why existing connections survive rule changes and why the real kube-proxy clears stale UDP entries.
- Run it beside the real one: one Service handled by each; compare chains side by side.
- Break it: kill the proxy and show rules keep working; delete a backend pod and show the window before the controller rewrites rules.

## Check before writing

- `service.kubernetes.io/service-proxy-name` behavior in 1.37.
- Whether kind node images ship both `iptables` (nft backend) and `nft` binaries.
- IPVS deprecation release.

## Done when

- Tests pass on the lab and in CI; cleanup leaves no rules behind.
