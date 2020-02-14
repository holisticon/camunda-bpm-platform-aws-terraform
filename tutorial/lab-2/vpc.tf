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

data "aws_security_group" "db_security_group" {
  name = "${var.shared_infrastructure_env}-rds-security-group"
}

output "db_security_group_id" {
  value = data.aws_security_group.db_security_group.id
}