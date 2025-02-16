/*=========== Elastic Container Registry Repos ===========*/
resource "aws_ecr_repository" "php_fpm" {
  name                 = "fly-laravel-php-fpm"
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_repository" "nginx" {
  name                 = "fly-laravel-nginx"
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = true
  }
}
