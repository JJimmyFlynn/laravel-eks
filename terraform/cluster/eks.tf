/*=========== EKS Cluster ===========*/
resource "aws_eks_cluster" "default" {
  name                          = "laravel-k8s"
  role_arn                      = aws_iam_role.cluster.arn
  bootstrap_self_managed_addons = true
  version                       = "1.32"
  enabled_cluster_log_types     = ["api", "controllerManager", "scheduler", "authenticator"]

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}


/*=========== Node Group ===========*/
// This node group exists so that Karpenter can provision the resources
// it needs to begin managing nodes. Karpenter nodes are managed
// outside this node group.
// TODO: Configure taints to only allow karpenter resources
resource "aws_eks_node_group" "critical" {
  node_group_name = "critical-services"
  cluster_name    = aws_eks_cluster.default.name
  node_role_arn   = aws_iam_role.karpenter_node.arn
  subnet_ids      = aws_subnet.private.*.id
  instance_types  = ["t3.medium"]

  taint {
    effect = "NO_SCHEDULE"
    key    = "CriticalAddonsOnly"
  }

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.karpenter-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.karpenter-AmazonEKSCNIPolicy,
    aws_iam_role_policy_attachment.karpenter-AmazonEKSWorkerNodePolicy
  ]
}
