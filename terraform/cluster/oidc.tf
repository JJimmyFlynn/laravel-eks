resource "aws_iam_openid_connect_provider" "default" {
  url            = one(aws_eks_cluster.default[*].identity[0].oidc[0].issuer)
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
