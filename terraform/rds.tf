# Customer-managed key so we control rotation and can audit key usage
# via CloudTrail - relevant for financial data.
resource "aws_kms_key" "rds" {
  description         = "${var.project} RDS encryption"
  enable_key_rotation = true
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}"
  subnet_ids = aws_subnet.data[*].id
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project}-${var.environment}"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100 # storage autoscaling headroom
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = "wallet_app"
  # Let RDS own the master password: it lands in Secrets Manager
  # automatically, rotates automatically, and never touches tfstate.
  manage_master_user_password = true

  multi_az               = var.db_multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period   = 30
  backup_window             = "02:00-03:00"
  maintenance_window        = "sun:03:30-sun:04:30"
  delete_automated_backups  = false
  copy_tags_to_snapshot     = true
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project}-${var.environment}-final"

  auto_minor_version_upgrade = true

  parameter_group_name = aws_db_parameter_group.main.name
}

resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.project}-pg16-"
  family      = "postgres16"

  # Refuse unencrypted connections from the app tier.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}
