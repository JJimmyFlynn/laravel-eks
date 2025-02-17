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

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller_role.arn
}

output "secrets_provider_role_arn" {
  value = aws_iam_role.secrets_provider.arn
}

output "nginx_image" {
  value = data.aws_ecr_image.laravel_nginx.image_uri
}

output "php_fpm_image" {
  value = data.aws_ecr_image.laravel_php_fpm.image_uri
}

output "security_group_allow_cloudfront_inbound_id" {
  value = aws_security_group.allow_cloudfront_inbound.id
}
