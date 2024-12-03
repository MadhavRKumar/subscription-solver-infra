resource "aws_db_instance" "postgres" {
  identifier                  = "main"
  allocated_storage           = 10
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "16.4"
  instance_class              = "db.m5.large"
  manage_master_user_password = true
  username                    = "main"
  skip_final_snapshot = true
  apply_immediately = true

  tags = {
    Name = "main"
  }

}
