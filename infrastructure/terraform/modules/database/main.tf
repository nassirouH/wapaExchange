variable "name"               { type = string }
variable "vpc_id"             { type = string }
variable "subnet_ids"         { type = list(string) }
variable "app_security_group" { type = string }
variable "db_password"        { type = string, sensitive = true }

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "Postgres ingress from app tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-pg"
  engine                  = "postgres"
  engine_version          = "16.4"
  instance_class          = "db.t4g.small"
  allocated_storage       = 50
  max_allocated_storage   = 200
  storage_type            = "gp3"
  storage_encrypted       = true
  multi_az                = true
  db_name                 = "wapaexchange"
  username                = "wapa"
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  backup_retention_period = 7
  backup_window           = "02:00-03:00"
  maintenance_window      = "Mon:03:30-Mon:04:30"
  deletion_protection     = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.name}-pg-final"
  apply_immediately       = false
  performance_insights_enabled = true
}

resource "aws_secretsmanager_secret" "db_url" {
  name = "${var.name}/database_url"
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id = aws_secretsmanager_secret.db_url.id
  secret_string = format(
    "postgresql://%s:%s@%s:%s/%s?sslmode=require",
    aws_db_instance.this.username,
    var.db_password,
    aws_db_instance.this.address,
    aws_db_instance.this.port,
    aws_db_instance.this.db_name,
  )
}

output "endpoint"              { value = aws_db_instance.this.endpoint }
output "connection_secret_arn" { value = aws_secretsmanager_secret.db_url.arn }
