resource "aws_ecr_repository" "default" {
  name = "fly-laravel"
  image_tag_mutability = "MUTABLE"
}
