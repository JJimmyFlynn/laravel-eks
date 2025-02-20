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

module "karpenter_fargate_profile" {
  source = "../karpenter-fargate"
  cluster_name = aws_eks_cluster.default.name
  iam_role_name = "laravelK8sFargatePodExecution"
  profile_name = "larvael-k8s-karpenter"
  subnet_ids = aws_subnet.private.*.id
  selectors = [
    {
      namespace: "karpenter"
    },
    {
      namespace: "kube-system",
      labels: {
        k8s-app: "kube-dns"
      }
    }
  ]
}
