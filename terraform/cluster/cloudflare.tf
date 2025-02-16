provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_dns_record" "default" {
  zone_id = var.cloudflare_zone_id
  name    = "laravel-k8s.johnjflynn.net"
  ttl     = 60
  type    = "CNAME"
  content = aws_cloudfront_distribution.default.domain_name
  proxied = false
}
