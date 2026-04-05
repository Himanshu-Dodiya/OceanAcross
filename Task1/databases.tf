resource "aws_db_subnet_group" "private_db_subnet" {
  name = "private-db-subnet"
  subnet_ids = aws_subnet.private[*].id

}

resource "random_password" "rds_password" {
    length  = 16
    special = true
    override_special = "!@#$%^&*()_+-="
  
}

resource "aws_secretsmanager_secret" "rds_secret" {
    name = "payroll/rds/credentials"
    description = "RDS credentials for payroll application"
  
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
    secret_id = aws_secretsmanager_secret.rds_secret.id
    secret_string = jsonencode({
        username = "admin",
        password = random_password.rds_password.result
        engine = "postgres",
        host = aws_db_instance.payroll_rds.endpoint,
        port = 5432,
        dbname = "payroll_db"
    })
  
}

resource "aws_db_instance" "payroll_rds" {
  identifier = "payroll-postgres"

  engine               = "postgres"
  engine_version       = "16"
  instance_class       = var.rds_instance_type
  allocated_storage    = 20
  db_name              = "payroll_db"

  username = "admin"
  password = random_password.rds_password.result

  multi_az             = true
  db_subnet_group_name = aws_db_subnet_group.private_db_subnet.name

  vpc_security_group_ids = [
    aws_security_group.tenant_sg["company"].id,
    aws_security_group.tenant_sg["bureau"].id,
    aws_security_group.tenant_sg["employee"].id
  ]

  skip_final_snapshot   = true
  publicly_accessible   = false
  deletion_protection   = false

  tags = {
    Name = "payroll-rds"
  }
}