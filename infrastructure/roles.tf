module "iam_assumable_role_ecs_task" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version               = "~> 2.0"
  trusted_role_services = ["ecs-tasks.amazonaws.com"]
  create_role           = true
  role_name             = "${var.environment_name}-ecs-task-execution-role"
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  role_requires_mfa = false

  tags = {
    Terraform   = "true"
    Environment = var.environment_name
  }
}