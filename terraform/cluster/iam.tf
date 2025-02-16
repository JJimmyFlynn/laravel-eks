/*=========== Assume Role/Trust Policy Definitions ===========*/
data "aws_iam_policy_document" "eks_general_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    principals {
      identifiers = ["eks.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "ec2_general_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      identifiers = [aws_iam_openid_connect_provider.default.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "${aws_iam_openid_connect_provider.default.url}:aud"
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
      variable = "${aws_iam_openid_connect_provider.default.url}:sub"
    }
  }
}

# CSI Secrets Provider
data "aws_iam_policy_document" "secrets_provider_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      identifiers = [aws_iam_openid_connect_provider.default.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "${aws_iam_openid_connect_provider.default.url}:aud"
    }
    condition {
      test     = "StringEquals"
      values   = [
        "system:serviceaccount:laravel:ascp",
        "system:serviceaccount:kube-system:external-dns"
      ]
      variable = "${aws_iam_openid_connect_provider.default.url}:sub"
    }
  }
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      values = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    condition {
      test     = "StringLike"
      values = ["repo:JJimmyFlynn/laravel-eks:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

/*=========== Policy Definitions ===========*/
# The AWS LB Controller requires a role with appropriate
# permissions to manage ALBs/NLBs and associate resources
# such as security groups for the LB and rules in
# the node security groups
resource "aws_iam_policy" "alb_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("./alb_iam_policy.json") // recommended by AWS
}

data "aws_iam_policy_document" "get_ssm_parameters" {
  statement {
    sid    = "AllowAccessToEnvironmentParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]

    resources = ["arn:aws:ssm:us-east-1:654654165875:parameter/laravel-k8s/*"]
  }
}

resource "aws_iam_policy" "allow_get_ssm_env_params" {
  name   = "GetSSMEnvironmentParams"
  policy = data.aws_iam_policy_document.get_ssm_parameters.json
}

data "aws_iam_policy_document" "ecr_push_pull" {
  statement {
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [
      aws_ecr_repository.php_fpm.arn,
      aws_ecr_repository.nginx.arn
    ]
  }
}

resource "aws_iam_policy" "allow_ecr_push_pull" {
  name = "ECRPushPull"
  policy = data.aws_iam_policy_document.ecr_push_pull.json
}

/*=========== Role Definitions ===========*/
resource "aws_iam_role" "cluster" {
  name = "eks-cluster-role-laravel"
  assume_role_policy = data.aws_iam_policy_document.eks_general_assume_role.json
}

resource "aws_iam_role" "node_group" {
  name = "eks-node-group-laravel"
  assume_role_policy = data.aws_iam_policy_document.ec2_general_assume_role.json
}

resource "aws_iam_role" "alb_controller_role" {
  name               = "AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

resource "aws_iam_role" "secrets_provider" {
  name               = "EKSSecretsProviderRole"
  assume_role_policy = data.aws_iam_policy_document.secrets_provider_assume_role.json
}

resource "aws_iam_role" "github_actions" {
  name = "laravelK8sGithubActions"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
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

resource "aws_iam_role_policy_attachment" "alb_controller_role_attachment" {
  policy_arn = aws_iam_policy.alb_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}

resource "aws_iam_role_policy_attachment" "secrets_provider_get_ssm_params" {
  policy_arn = aws_iam_policy.allow_get_ssm_env_params.arn
  role       = aws_iam_role.secrets_provider.name
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_push_pull" {
  policy_arn = aws_iam_policy.allow_ecr_push_pull.arn
  role       = aws_iam_role.github_actions.name
}
