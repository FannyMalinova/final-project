####################################
# Task and container definition
####################################

resource "aws_ecs_task_definition" "ecs-budget-app" {
  family                   = "${local.prefix}-ecs-budget-app"
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

      portMappings = [
          {
            containerPort = 5000
            hostPort      = 5000
          }
        ]

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
          awslogs-group         = data.terraform_remote_state.setup.outputs.ecs-task-logs-bap.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "bap"
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

#############################
# Service definition
#############################

resource "aws_ecs_service" "budget-app" {
  name                   = "${local.prefix}-budget-app"
  cluster                = data.terraform_remote_state.setup.outputs.ecs-main.name 
  task_definition        = aws_ecs_task_definition.ecs-budget-app.family
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  network_configuration {
    assign_public_ip = true

    subnets = [
      data.terraform_remote_state.setup.outputs.private-a.id,
      data.terraform_remote_state.setup.outputs.private-a.id
    ]

    security_groups = [data.terraform_remote_state.setup.outputs.ecs-service.id]
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.setup.outputs.budget-app-target
    container_name   = "budget-app"
    container_port   = 5000
  }

}

    