######################
# RDS Database
######################

resource "aws_db_subnet_group" "db-subnet-main" {
  name = "${local.prefix}-db-subnet-main"
  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}
resource "aws_security_group" "rds" {
  description = "Allow access to the DB instance"
  name        = "${local.prefix}-rds-inbound-access"
  vpc_id      = aws_vpc.vpc-main.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
  }

  tags = {
    Name = "${local.prefix}-db-security-group"
  }
}

resource "aws_db_instance" "db-main" {
  identifier                 = "${local.prefix}-db"
  db_name                    = "budget-app-db"
  allocated_storage          = 20
  storage_type               = "gp2"
  engine                     = "postgres"
  engine_version             = "15.3"
  auto_minor_version_upgrade = true
  instance_class             = "db.t4g.micro"
  username                   = var.db_username
  password                   = var.db_password
  skip_final_snapshot        = true
  db_subnet_group_name       = aws_db_subnet_group.db-subnet-main.name
  multi_az                   = false
  backup_retention_period    = 0
  vpc_security_group_ids     = [aws_security_group.rds.id]

  tags = {
    Name = "${local.prefix}-db-main"
  }
}
