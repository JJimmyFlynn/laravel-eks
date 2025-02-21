resource "aws_security_group" "allow_cloudfront_inbound" {
  name   = "AllowCloudFrontInbound"
  vpc_id = aws_vpc.default.id

  tags = {
    "Name" = "AllowCloudFrontInbound"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_cloudfront" {
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.allow_cloudfront_inbound.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

resource "aws_security_group" "karpenter_node" {
  name = "KarpenterNodeLaravelK8s"
  vpc_id = aws_vpc.default.id
  tags = {
    "Name" = "KarpenterNodeLaravelK8s"
    "karpenter.sh/discovery" = "laravel-k8s"
    "aws:eks:cluster-name" = "laravel-k8s"
    "kubernetes.io/cluster/laravel-k8s": "owned"
  }
}

resource "aws_vpc_security_group_ingress_rule" "karpenter_node_allow_self" {
  ip_protocol       = "-1"
  security_group_id = aws_security_group.karpenter_node.id
  referenced_security_group_id = aws_security_group.karpenter_node.id
}

resource "aws_vpc_security_group_egress_rule" "karpenter_node_allow_all_outbound" {
  ip_protocol       = "-1"
  security_group_id = aws_security_group.karpenter_node.id
  cidr_ipv4 = "0.0.0.0/0"
}

