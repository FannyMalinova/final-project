######################################
# ECS cluster
#####################################

resource "aws_ecs_cluster" "ecs-main" {
  name = "${local.prefix}-cluster"
}

#####################################
# Log group
#####################################

resource "aws_cloudwatch_log_group" "ecs-task-logs-bap" {
  name = "${local.prefix}-logs-bap"
}

#####################################
# Security group
#####################################

resource "aws_security_group" "ecs-service" {
  description = "Access rules for the ECS service."
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.vpc-main.id

##############################
# Outbound access to endpoints
##############################

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

##############################
# RDS connectivity
##############################

  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block,
    ]
  }

##############################
# HTTP inbound access
##############################

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [
      aws_security_group.elb.id
    ]
  }
}
