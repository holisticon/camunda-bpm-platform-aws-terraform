resource "aws_ecs_cluster" "camunda_cluster" {
  name = "${var.environment_name}_camunda_cluster"

  tags = {
    Environment = var.environment_name
  }
}
