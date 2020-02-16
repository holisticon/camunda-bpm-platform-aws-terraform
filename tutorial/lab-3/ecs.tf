resource "aws_ecs_cluster" "camunda_cluster" {
  name = "${var.environment_name}_camunda_cluster"

  tags = {
    Terraform   = "true"
    Environment = var.environment_name
  }
}

data "aws_alb" "selected" {
  name = "${var.shared_infrastructure_env}-alb"
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_alb.selected.arn
  port              = 443
}


resource "aws_alb_target_group" "camunda" {
  name        = "${var.environment_name}-camunda-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"
  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/"
    matcher             = "200-299"
  }
}


resource "aws_alb_listener_rule" "camunda" {
  listener_arn = data.aws_lb_listener.selected443.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.camunda.arn
  }

  condition {
    host_header {
      values = ["${var.environment_name}.${var.domain_name}"]
    }
  }
}

resource "aws_ecs_service" "camunda_service" {
  name                              = "${var.environment_name}-camunda_service"
  cluster                           = aws_ecs_cluster.camunda_cluster.id
  task_definition                   = module.ecs-fargate-task-definition.aws_ecs_task_definition_td_arn
  desired_count                     = 3
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = aws_alb_target_group.camunda.arn
    container_name   = "camunda-demo"
    container_port   = 8080
  }

  network_configuration {
    security_groups  = [data.aws_security_group.ecs_task_security_group.id]
    subnets          = data.aws_subnet_ids.selected.ids
    assign_public_ip = true
  }

  //  lifecycle {
  //    ignore_changes = ["desired_count"]
  //  }

  tags = {
    Terraform   = "true"
    Environment = var.environment_name
  }
}
/*
data "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.shared_infrastructure_env}-ecs-task-execution-role"
}*/

resource "aws_cloudwatch_log_group" "camunda_demo" {
  name              = "${var.environment_name}-camunda"
  retention_in_days = 1

  tags = {
    Terraform   = "true"
    Environment = var.environment_name
  }
}

data "aws_region" "current" {}

module "ecs-fargate-task-definition" {
  source           = "cn-terraform/ecs-fargate-task-definition/aws"
  version          = "1.0.7"
  container_image  = "camunda/camunda-bpm-platform:latest"
  container_name   = "camunda-demo"
  container_port   = "8080"
  container_cpu    = 1024
  container_memory = 2048
  name_preffix     = var.environment_name
  profile          = "default"
  region           = data.aws_region.current.name
  environment = [
    {
      name  = "DB_DRIVER",
      value = "com.mysql.jdbc.Driver"
    },
    {
      name  = "DB_URL",
      value = "jdbc:mysql://${aws_rds_cluster.db.endpoint}:${aws_rds_cluster.db.port}/${aws_rds_cluster.db.database_name}"
    },
    {
      name  = "DB_USERNAME",
      value = aws_rds_cluster.db.master_username
    },
    {
      name  = "DB_PASSWORD",
      value = aws_rds_cluster.db.master_password
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.camunda_demo.name
      awslogs-stream-prefix = "camunda"
    }
    secretOptions = []
  }
}