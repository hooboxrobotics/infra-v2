locals {
  env  = "prd"
  name = "hbx-${local.db_engine}-${local.env}"

  db_engine  = "redis"
  db_version = "7.1"
  db_port    = 6379
}

resource "aws_security_group" "database" {
  name   = "database"
  vpc_id = data.aws_vpc.network.id

  ingress {
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = concat([data.aws_vpc.network.cidr_block], data.aws_vpc.network.cidr_block_associations.*.cidr_block)
  }
}

module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  cluster_id               = local.name
  create_cluster           = true
  create_replication_group = false

  engine          = local.db_engine
  engine_version  = local.db_version
  node_type       = "cache.t4g.small"
  num_cache_nodes = 2
  az_mode         = "cross-az"

  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately  = true

  vpc_id = data.aws_vpc.network.id

  security_group_ids = [aws_security_group.database.id]
  subnet_ids         = data.aws_subnets.database.ids
}
