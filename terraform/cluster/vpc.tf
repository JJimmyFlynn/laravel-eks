locals {
  az_count = 3
}

/****************************************
* Base VPC
*****************************************/
resource "aws_vpc" "default" {
  enable_dns_hostnames = true
  cidr_block           = "10.10.0.0/16"
}

/****************************************
* Subnets
*****************************************/
resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, local.az_count, count.index)

  tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery" = "laravel-k8s"
  }
}

resource "aws_subnet" "public" {
  count             = local.az_count
  vpc_id            = aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, local.az_count, count.index + local.az_count) // pickup where private subnet creation left off
  tags = {
    "kubernetes.io/role/elb" = 1
  }
}

/****************************************
* Internet Gateway
*****************************************/
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

/****************************************
* Elastic IPs
*****************************************/
resource "aws_eip" "nat" {
  count = local.az_count
}

/****************************************
* NAT Gateway
*****************************************/
resource "aws_nat_gateway" "default" {
  count             = local.az_count
  subnet_id         = aws_subnet.public.*.id[count.index]
  connectivity_type = "public"
  allocation_id     = aws_eip.nat.*.id[count.index]

  depends_on = [aws_internet_gateway.default]
}

/****************************************
* Route Tables
*****************************************/
// PUBLIC WEB ACCESS
resource "aws_route_table" "web_access" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "web_access" {
  count          = local.az_count
  route_table_id = aws_route_table.web_access.id
  subnet_id      = aws_subnet.public.*.id[count.index]
}

// OUTBOUND ONLY WEB ACCESS
resource "aws_route_table" "outbound_web_access" {
  count  = local.az_count
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.default.*.id[count.index]
  }
}

resource "aws_route_table_association" "private_web_access" {
  count          = local.az_count
  route_table_id = aws_route_table.outbound_web_access.*.id[count.index]
  subnet_id      = aws_subnet.private.*.id[count.index]
}
