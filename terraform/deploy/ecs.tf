####################################
# Task definition
####################################

resource "aws_ecs_task_definition" "ecs-api" {
  family                   = "${local.prefix}-ecs-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.terraform_remote_state.setup.outputs.task-execution-role
  task_role_arn            = data.terraform_remote_state.setup.outputs.app-task-role

  container_definitions = jsonencode([
    {
      name              = "budget-app"
      image             = var.ecr-app-image
      essential         = true
      memoryReservation = 256

      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.db-main.address
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.db-main.db_name
        },
        {
          name  = "DB_USER"
          value = aws_db_instance.db-main.username
        },
        {
          name  = "DB_PASS"
          value = aws_db_instance.db-main.password
        },
        {
          name  = "ALLOWED_HOSTS"
          value = "*"
        }
      ]
      mountPoints = [
        {
          readOnly      = false
          containerPath = "/vol/web/static"
          sourceVolume  = "static"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = data.terraform_remote_state.setup.outputs.ecs-task-logs-api.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "api"
        }
      }
    }

  ])

  volume {
    name = "static"
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

######################################
# Security group
######################################

#####################################
# Security group
#####################################

resource "aws_security_group" "ecs-service" {
  description = "Access rules for the ECS service."
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.vpc-main.id

  # Outbound access to endpoints
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDS connectivity
  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block,
    ]
  }

  # HTTP inbound access
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

