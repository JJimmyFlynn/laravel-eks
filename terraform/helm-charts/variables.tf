variable "region" {
  type        = string
  description = "The AWS region where resource will be created"
}

variable "role_arn" {
  type        = string
  description = "ARN of the role for terraform to assume"
}

variable "domain" {
  type = string
  description = "The main domain on which the application will be accessed"
}

variable "alb_domain" {
  type = string
  description = "Domain that will be assigned to the ALB ingress CNAME via in Cloudflare via external-dns"
}
