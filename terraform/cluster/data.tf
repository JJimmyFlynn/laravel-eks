data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

data "aws_ecr_image" "laravel_nginx" {
  repository_name = aws_ecr_repository.nginx.name
  image_tag       = "latest"
}

data "aws_ecr_image" "laravel_php_fpm" {
  repository_name = aws_ecr_repository.php_fpm.name
  image_tag       = "latest"
}

data "aws_acm_certificate" "cloudfront_domain_certificate" {
  domain   = var.cloudfront_domain
  statuses = ["ISSUED"]
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
