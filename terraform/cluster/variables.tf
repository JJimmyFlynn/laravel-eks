variable "region" {
  type        = string
  description = "The AWS region where resource will be created"
}

variable "role_arn" {
  type        = string
  description = "ARN of the role for terraform to assume"
}

variable "cloudfront_domain" {
  type        = string
  description = "Domain alias for the cloudfront distribution. Should match host name of Laravel app"
}

variable "alb_domain" {
  type        = string
  description = "The domain name of the ALB that will be created by AWS Load Balancer Controller"
}

variable "admin_arn" {
  type = string
}

variable "aurora_min_capacity" {
  type        = number
  default     = 1
  description = "The minimum ACUs used in the RDS autoscaling policy. Must be less than `aurora_min_capacity`. Range of 0.5 - 128"
}

variable "aurora_max_capacity" {
  type        = number
  default     = 4
  description = "The maximum ACUs used in the RDS autoscaling policy. Must be more than `aurora_min_capacity`. Range of 1 - 128"
}

variable "aurora_instance_count" {
  type        = number
  default     = 1
  description = "The total number of instances to create in the RDS cluster"
}

variable "parameter_store_path" {
  type        = string
  description = "The path at which ssm parameters are stored for this application/stage. e.g. /example-application/dev"
}

variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}
