output "vpc_id" {
  value = aws_vpc.default.id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.default.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.default.endpoint
}

output "eks_cluster_ca_certificate" {
  value = aws_eks_cluster.default.certificate_authority.0.data
}
