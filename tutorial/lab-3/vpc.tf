data "aws_vpc" "selected" {
  tags = {
    Environment = var.shared_infrastructure_env
  }
}

output "vpc_id" {
  value = data.aws_vpc.selected.id
}

data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.selected.id
}

output "subnet_ids" {
  value = data.aws_subnet_ids.selected.ids
}

data "aws_security_group" "unrestricted" {
  name = "${var.shared_infrastructure_env}-unrestricted-security-group"
}

output "unrestricted_sg_id" {
  value = data.aws_security_group.unrestricted.id
}