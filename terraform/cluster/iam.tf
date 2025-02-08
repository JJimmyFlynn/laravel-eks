resource "aws_iam_role" "cluster" {
  name = "eks-cluster-role-laravel"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role" "node_group" {
  name = "eks-node-group-laravel"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "laravel-k8s-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "laravel-k8s-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "laravel-k8s-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# The AWS LB Controller requires a role with appropriate
# permissions to manage ALBs/NLBs and associate resources
# such as security groups for the LB and rules in
# the node security groups
resource "aws_iam_role" "alb_controller_role" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.default.arn
        },
      },
    ]
  })
}

resource "aws_iam_policy" "alb_policy" {
  name = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("./alb_iam_policy.json") // recommended by AWS
}

resource "aws_iam_role_policy_attachment" "alb_controller_role_attachment" {
  policy_arn = aws_iam_policy.alb_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}

# AWS Secrets Provider
resource "aws_iam_role" "secrets_provider" {
  name = "EKSSecretsProviderRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.default.arn
        },
      },
    ]
  })
}

data "aws_iam_policy_document" "get_sss_parameters_by_path" {
  statement {
    sid     = "AllowAccessToEnvironmentParameters"
    actions = ["ssm:GetParametersByPath"]
    effect  = "Allow"

    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.parameter_store_path}"]
  }
}

resource "aws_iam_policy" "allow_get_ssm_env_params" {
  name   = "GetSSMEnvironmentParams"
  policy = data.aws_iam_policy_document.get_sss_parameters_by_path.json
}

resource "aws_iam_role_policy_attachment" "secrets_provider_get_ssm_params" {
  policy_arn = aws_iam_policy.allow_get_ssm_env_params.arn
  role       = aws_iam_role.secrets_provider.name
}
