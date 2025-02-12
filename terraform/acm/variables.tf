variable "region" {
  type        = string
  description = "The AWS region where resource will be created"
}

variable "role_arn" {
  type        = string
  description = "ARN of the role for terraform to assume"
}
