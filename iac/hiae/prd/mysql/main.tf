locals {
  env  = "prd"
  name = "hbx-${local.db_engine}-${local.env}"

  db_engine  = "mysql"
  db_version = "8.4"
  db_port    = 3306
}

ephemeral "random_password" "db_password" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_security_group" "database" {
  name   = "database"
  vpc_id = data.aws_vpc.network.id

  ingress {
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.network.cidr_block]
  }
}


module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.name

  engine            = local.db_engine
  engine_version    = local.db_version
  instance_class    = "db.t4g.small"
  allocated_storage = 5

  username = "user"
  port     = "3306"

  password_wo = ephemeral.random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.database.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  create_db_subnet_group = true
  subnet_ids             = data.aws_subnets.database.ids
  multi_az               = true

  family               = "${local.db_engine}${local.db_version}"
  major_engine_version = local.db_version

  deletion_protection = true

  parameters = [
    {
      name         = "lower_case_table_names"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "require_secure_transport"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "long_query_time"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "slow_query_log"
      value        = "1"
      apply_method = "immediate"
    }
  ]
}
