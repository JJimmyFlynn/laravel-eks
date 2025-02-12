resource "aws_acm_certificate" "laravel_k8s" {
  domain_name       = "laravel-k8s.johnjflynn.net"
  validation_method = "DNS"
}
