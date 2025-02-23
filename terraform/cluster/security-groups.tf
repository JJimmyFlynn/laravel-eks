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
