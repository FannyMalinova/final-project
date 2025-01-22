######################################
# ECS cluster
#####################################

resource "aws_ecs_cluster" "ecs-main" {
  name = "${local.prefix}-cluster"
}

#####################################
# Log group
#####################################

resource "aws_cloudwatch_log_group" "ecs-task-log-api" {
  name = "${local.prefix}-api"
}
