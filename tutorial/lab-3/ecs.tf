resource "aws_ecs_cluster" "camunda_cluster" {
  name = "${var.environment_name}-camunda-cluster"

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

/*
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
  # replace cidR_blocks with following line to restrict access to ECS tasks only
  # source_security_group_id = data.aws_security_group.alb.id
}
*/

data "aws_route53_zone" "zone" {
  name = "${var.domain_name}."
}

module "ecs-airg" {
  source = "github.com/holisticon/terraform-aws-airship-ecs-service.git?ref=terraform12"
  name = "${var.environment_name}-camunda"
  ecs_cluster_id = aws_ecs_cluster.camunda_cluster.id

  region = "eu-west-1"


  fargate_enabled = true

  awsvpc_enabled            = true
  awsvpc_subnets            = [data.aws_subnet_ids.selected.ids]
  awsvpc_security_group_ids = [data.aws_security_group.unrestricted.id]

  load_balancing_type = "application"

    # The ARN of the ALB, when left-out the service, 
  load_balancing_properties_lb_arn = data.aws_alb.selected.arn

  # http listener ARN
  load_balancing_properties_lb_listener_arn_https = data.aws_lb_listener.selected443.arn

  # The VPC_ID the target_group is being created in
  load_balancing_properties_lb_vpc_id = data.aws_vpc.selected.id

  # The route53 zone for which we create a subdomain
  load_balancing_properties_route53_zone_id = "${data.aws_route53_zone.zone.zone_id}"

  # health_uri defines which health-check uri the target 
  # group needs to check on for health_check, defaults to /ping
  load_balancing_properties_health_uri = "/"

  load_balancing_properties_https_enabled = true

  container_cpu = 1024
  container_memory = 2048
  container_port   = 8080
  bootstrap_container_image = "camunda/camunda-bpm-platform:latest"

  # force_bootstrap_container_image to true will 
  # force the deployment to use var.bootstrap_container_image as container_image
  # if container_image is already deployed, no actual service update will happen
  # force_bootstrap_container_image = false

  # Initial ENV Variables for the ECS Task definition
  container_envvars = {
    ENV_VARIABLE = "SOMETHING"
  }

  # capacity_properties defines the size in task for the ECS Service.
  # Without scaling enabled, desired_capacity is the only necessary property
  # defaults to 2
  # With scaling enabled, desired_min_capacity and desired_max_capacity 
  # define the lower and upper boundary in task size
  capacity_properties_desired_capacity = "1"
}
