variable "cluster_name" {
  type = string
  description = "Name of the cluster into which the fargate profile will be provisioned"
}

variable "profile_name" {
  type = string
  description = "Name of the fargate profile to be created"
}

variable "iam_role_name" {
  type = string
  description = "Name of the IAM pod execution role to be created"
}

variable "subnet_ids" {
  type = list(string)
  description = "List of IDs of subnets to associate with the Fargate profile"
}

variable "selectors" {
  type = list(object({
    namespace = string
    labels = optional(map(string))
  }))
}
