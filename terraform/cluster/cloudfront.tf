resource "aws_cloudfront_distribution" "default" {
  enabled     = true
  comment     = "${var.cluster_name} - Front ALB"
  aliases     = [var.cloudfront_domain]
  price_class = "PriceClass_100" // NA & EU

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cloudfront_domain_certificate.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  origin {
    domain_name = var.alb_domain
    origin_id   = var.alb_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = var.alb_domain
    cache_policy_id          = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" // AWS Managed - UseOriginCacheControlHeaders-QueryStrings
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" // AWS Managed - AllViewer
    viewer_protocol_policy   = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
}
