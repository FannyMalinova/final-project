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
