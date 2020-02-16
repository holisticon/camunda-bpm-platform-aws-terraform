resource "aws_ecs_cluster" "camunda_cluster" {
  name = "${var.environment_name}_camunda_cluster"

  tags = {
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

resource "aws_alb_listener_rule" "camunda" {
  listener_arn = data.aws_lb_listener.selected443.arn

  action {
    type             = "forward"
    target_group_arn = module.camunda_ecs_fargate.target_group_arn
  }

  condition {
    host_header {
      values = ["${var.environment_name}.${var.domain_name}"]
    }
  }
}

locals {
  task_container_port = 8080
}

module "camunda_ecs_fargate" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "3.3.0"

  name_prefix            = "${var.environment_name}-camunda"
  vpc_id                 = data.aws_vpc.selected.id
  private_subnet_ids     = data.aws_subnet_ids.selected.ids
  lb_arn                 = data.aws_alb.selected.arn
  cluster_id             = aws_ecs_cluster.camunda_cluster.id
  task_container_image   = "camunda/camunda-bpm-platform:latest"
  task_definition_cpu    = 1024
  task_definition_memory = 2048
  desired_count          = 1
  // public ip is needed for default vpc, default is false
  task_container_assign_public_ip = true

  // port, default protocol is HTTP
  task_container_port = local.task_container_port

  task_container_environment = {
    DB_DRIVER   = "com.mysql.jdbc.Driver"
    DB_URL      = "jdbc:mysql://${aws_rds_cluster.db.endpoint}:${aws_rds_cluster.db.port}/${aws_rds_cluster.db.database_name}"
    DB_USERNAME = aws_rds_cluster.db.master_username
    DB_PASSWORD = aws_rds_cluster.db.master_password
  }

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  tags = {
    Environment = var.environment_name
  }
}

resource "aws_security_group_rule" "ingress_service" {
  security_group_id = module.camunda_ecs_fargate.service_sg_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = local.task_container_port
  to_port           = local.task_container_port
  cidr_blocks       = ["0.0.0.0/0"]
}
