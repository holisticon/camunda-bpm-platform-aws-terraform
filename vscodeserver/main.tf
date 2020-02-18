data "aws_region" "current" {}

data "aws_vpc" "selected" {
  tags = {
    Environment = var.shared_infrastructure_env
  }
}

data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_alb" "selected" {
  name = "${var.shared_infrastructure_env}-alb"
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_alb.selected.arn
  port              = 443
}

data "aws_security_group" "ecs_task_security_group" {
  name = "${var.shared_infrastructure_env}-ecs-task-security-group"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.shared_infrastructure_env}-ecs-task-execution-role"
}

resource "aws_alb_target_group" "tg" {
  for_each    = var.environment_name
  name        = "${each.value}-vscode-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path    = "/login"
    matcher = "200-299"
  }
}

resource "aws_alb_listener_rule" "forward" {
  for_each     = var.environment_name
  listener_arn = data.aws_lb_listener.selected443.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tg[each.value].arn
  }

  condition {
    host_header {
      values = ["${each.value}-vscode.awsterraformtraining.ml"]
    }
  }
}

resource "aws_ecs_cluster" "vscode" {
  for_each = var.environment_name
  name     = "${each.value}-vscode_cluster"

  tags = {
    Terraform   = "true"
    Environment = "${each.value}-vscode"
  }
}

resource "aws_ecs_service" "vscode" {
  for_each                          = var.environment_name
  name                              = "${each.value}-vscode"
  cluster                           = aws_ecs_cluster.vscode[each.value].id
  task_definition                   = aws_ecs_task_definition.vscodeserver.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = aws_alb_target_group.tg[each.value].arn
    container_name   = "vscodeserver"
    container_port   = 8080
  }

  network_configuration {
    security_groups  = [data.aws_security_group.ecs_task_security_group.id]
    subnets          = data.aws_subnet_ids.selected.ids
    assign_public_ip = true
  }

  tags = {
    Terraform   = "true"
    Environment = "${each.value}-vscode"
  }
}

locals {
  task_container_port = 8080
}

resource "aws_cloudwatch_log_group" "vscode" {
  name              = "vscodeserver"
  retention_in_days = 1

  tags = {
    Terraform   = "true"
    Environment = "vscode"
  }
}

resource "aws_ecs_task_definition" "vscodeserver" {
  family                   = "vscodeserver"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  container_definitions = <<EOF
[
  {
    "name": "vscodeserver",
    "image": "${var.container_image}",
    "networkMode": "awsvpc",
    "environment": [
      {
        "name": "PASSWORD",
        "value": "${var.password}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${aws_cloudwatch_log_group.vscode.name}",
        "awslogs-stream-prefix": "vscode"
      }
    },
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080,
        "protocol": "tcp"
      }
    ]
  }
]
EOF

  tags = {
    Terraform   = "true"
    Environment = "vscode"
  }
}
