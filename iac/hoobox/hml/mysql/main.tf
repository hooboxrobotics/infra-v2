resource "aws_db_parameter_group" "config" {
  name   = "hbx-hml-mysql84-shared"
  family = "mysql8.4"

  parameter {
    name  = "lower_case_table_names"
    value = "1"

    apply_method = "pending-reboot"
  }

  parameter {
    name  = "require_secure_transport"
    value = "1"

    apply_method = "pending-reboot"
  }

  parameter {
    name  = "long_query_time"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }
}