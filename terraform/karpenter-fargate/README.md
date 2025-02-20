> [!Note]
> WIP

### Provisions a fargate profile and IAM pod executions role for Karpenter to run in an existing EKS cluster via Fargate

### Why?
In order for Karpenter to manage compute for a cluster, it first needs compute to run on; creating a chicken and egg problem. Common solutions to this include creating a small Managed Node Group in the cluster to act as compute for Karpenter and running Karpenter-namespaced resources via Fargate. This module implements the latter.

Offloading Karpenter to Fargate helps simplify the management of its resources by effectively sidelining it from the rest of the cluster.  The removes complexities around running a node for Karpenter resources--such as dealing with taints/affinities/etc--and allows your workload resources to run on Karpenter managed nodes.
