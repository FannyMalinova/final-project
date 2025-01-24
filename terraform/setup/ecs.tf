######################################
# ECS cluster
#####################################

resource "aws_ecs_cluster" "ecs-main" {
  name = "${local.prefix}-cluster"
}

#####################################
# Log group
#####################################

resource "aws_cloudwatch_log_group" "ecs-task-logs-api" {
  name = "${local.prefix}-logs-api"
}
