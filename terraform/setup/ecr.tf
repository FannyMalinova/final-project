###################
# Create ESR repository for storing Docker images in AWS.
###################

resource "aws_ecr_repository" "budget-app-repo" {
  name                 = "budget-app-${local.prefix}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

