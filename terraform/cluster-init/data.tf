data "terraform_remote_state" "cluster" {
  backend = "s3"
  config = {
    bucket = "flynn-tfstate-php-infra-poc"
    key    = "laravel-k8s"
    region = "us-east-1"
  }
}
