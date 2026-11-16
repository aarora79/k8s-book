# Chapter 7: A Service by hand

Status: planned. This file is the chapter's plan. The code and the full text come next, following the template in the top-level README.

## What you will build

A small kube-proxy. It watches Services and EndpointSlices and writes NAT rules so traffic to a Service's ClusterIP reaches one of its pods, chosen at random.

## What the real one does

The real kube-proxy runs on every node and programs the kernel. In [iptables mode](https://github.com/kubernetes/kubernetes/blob/v1.34.0/pkg/proxy/iptables/proxier.go), still the default, it writes a `KUBE-SERVICES` chain that jumps to a chain per Service, which picks a chain per endpoint with the `statistic` match and rewrites the destination. The [nftables mode](https://github.com/kubernetes/kubernetes/blob/v1.34.0/pkg/proxy/nftables/proxier.go), generally available since Kubernetes 1.33, does the same with maps, so a lookup costs the same with 10 Services or 10,000.

## Scope

| Supported | Left out |
| --- | --- |
| ClusterIP Services, TCP | NodePort, LoadBalancer, UDP, SCTP |
| Random choice among ready endpoints | Session affinity, topology hints, traffic policies |
| Rules in a chain of your own, rebuilt on each change | Incremental updates, conntrack cleanup |

## Build it (planned steps)

1. Read: dump the real rules on `lab-worker` with `iptables-save -t nat | grep KUBE` and trace one Service by hand.
2. Write one rule by hand for a fake ClusterIP and curl it from the node.
3. A program that watches Services and EndpointSlices and rewrites a `TOY-SERVICES` chain.
4. Probabilities: give each endpoint the right `statistic` probability so traffic spreads evenly.

## Run it beside the real one

Create a Service with the label `toy-proxy=true` and an unused ClusterIP range of your own, so the real kube-proxy and yours never handle the same address. Compare your chain with `KUBE-SVC-*`.

## Break it

1. Scale the backing Deployment to zero and curl the Service. Decide what your rules should do.
2. Kill your proxy and check whether existing rules keep working. They do: the kernel holds them.

## Improving and expanding

1. Easy: support multiple ports per Service.
2. Medium: write the same rules with `nft` maps.
3. Hard: update rules incrementally instead of rebuilding the chain.

## Further reading

- [Virtual IPs and Service proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/)
- [NFTables mode for kube-proxy](https://kubernetes.io/blog/2025/02/28/nftables-kube-proxy/)
- [Luca Berton, kube-proxy iptables mode on kind](https://lucaberton.com/blog/kube-proxy-iptables-nftables-kubernetes-services/)
