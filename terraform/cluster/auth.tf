
# Access entry for the primary cluster admin AWS role or user
resource "aws_eks_access_entry" "laravel-eks-admin" {
  cluster_name      = aws_eks_cluster.default.name
  principal_arn     = var.admin_arn
  kubernetes_groups = []
  type              = "STANDARD"
}

# Bind managed cluster administrative policies to the cluster AWS role or user
resource "aws_eks_access_policy_association" "laravel-k8s-admin-policy-binding" {
  cluster_name  = aws_eks_cluster.default.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = var.admin_arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "laravel-k8s-cluster-admin-binding" {
  cluster_name  = aws_eks_cluster.default.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.admin_arn

  access_scope {
    type = "cluster"
  }
}
