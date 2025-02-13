resource "aws_ssm_parameter" "env_app_url" {
  name  = "${var.parameter_store_path}/APP_URL"
  type  = "String"
  value = "https://laravel-k8s.johnjflynn.net"
}

resource "aws_ssm_parameter" "env_app_name" {
  name  = "${var.parameter_store_path}/APP_NAME"
  type  = "String"
  value = "laravel-k8s"
}

resource "aws_ssm_parameter" "env_app_environment" {
  name  = "${var.parameter_store_path}/APP_ENV"
  type  = "String"
  value = "dev"
}

resource "aws_ssm_parameter" "env_db_connection" {
  name  = "${var.parameter_store_path}/DB_CONNECTION"
  type  = "String"
  value = "mysql"
}

resource "aws_ssm_parameter" "env_db_host" {
  name  = "${var.parameter_store_path}/DB_HOST"
  type  = "String"
  value = aws_rds_cluster.default.endpoint
}

resource "aws_ssm_parameter" "env_db_username" {
  name  = "${var.parameter_store_path}/DB_USERNAME"
  type  = "String"
  value = aws_rds_cluster.default.master_username
}

resource "aws_ssm_parameter" "env_db_database" {
  name  = "${var.parameter_store_path}/DB_DATABASE"
  type  = "String"
  value = aws_rds_cluster.default.database_name
}

