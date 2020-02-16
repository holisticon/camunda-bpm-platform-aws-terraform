resource "aws_rds_cluster" "db" {
  cluster_identifier = "${var.environment_name}-camunda-db"
  engine = "aurora"
  engine_mode = "serverless"
  engine_version = "5.6.10a"
  master_username = "username"
  master_password = "password"
  database_name = "camunda"

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [data.aws_security_group.unrestricted.id]

  apply_immediately = true
  skip_final_snapshot = true
  final_snapshot_identifier = "${var.environment_name}-final-snapshot"

  tags = {
    Environment = var.environment_name
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = var.environment_name
  subnet_ids = data.aws_subnet_ids.selected.ids

  tags = {
    Environment = var.environment_name
  }
}
