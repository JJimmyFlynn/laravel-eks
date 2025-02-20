data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  name                 = var.iam_role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "pod_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.default.name
}

resource "aws_eks_fargate_profile" "default" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = var.profile_name
  pod_execution_role_arn = aws_iam_role.default.arn
  subnet_ids             = var.subnet_ids

  dynamic "selector" {
    for_each = var.selectors
    content {
      namespace = selector.value["namespace"]
      labels = selector.value["labels"]
    }
  }
}
