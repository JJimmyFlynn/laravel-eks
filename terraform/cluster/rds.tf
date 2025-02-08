/****************************************
 * Aurora Serverless RDS
*****************************************/
data "aws_ssm_parameter" "rds_password" {
  name = "/laravel-k8s/dev/DB_PASSWORD"
}

resource "aws_db_subnet_group" "default" {
  name       = "laravel-k8s"
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_rds_cluster" "default" {
  cluster_identifier   = "laravel-k8s"
  engine               = "aurora-mysql"
  engine_version       = "8.0"
  engine_mode          = "provisioned"
  master_username      = "admin"
  master_password      = "example-password"
  database_name        = "laravel"
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_allow_vpc.id]


  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }
}

resource "aws_rds_cluster_instance" "default" {
  identifier           = "laravel-k8s-writer"
  count                = var.aurora_instance_count
  cluster_identifier   = aws_rds_cluster.default.id
  engine               = aws_rds_cluster.default.engine
  engine_version       = aws_rds_cluster.default.engine_version
  instance_class       = "db.serverless"
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.default.name
}

# Security Group
resource "aws_security_group" "rds_allow_vpc" {
  vpc_id      = aws_vpc.default.id
  name        = "rds-laravel-k8s"
  description = "Allow inbound traffic from local VPC"
}

resource "aws_vpc_security_group_ingress_rule" "rds_allow_webserver" {
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.rds_allow_vpc.id
  cidr_ipv4         = aws_vpc.default.cidr_block
}
