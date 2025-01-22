resource "aws_ecs_cluster" "ecs-main" {
  name = "${local.prefix}-cluster"
}
