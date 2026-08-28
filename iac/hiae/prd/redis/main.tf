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

  replication_group_id     = local.name
  create_cluster           = false
  create_replication_group = true

  engine                     = local.db_engine
  engine_version             = local.db_version
  node_type                  = "cache.t4g.small"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  transit_encryption_enabled = true
  transit_encryption_mode    = "preferred"

  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately  = true

  vpc_id = data.aws_vpc.network.id

  security_group_ids = [aws_security_group.database.id]
  subnet_ids         = data.aws_subnets.database.ids
}

resource "aws_ssm_parameter" "redis_host" {
  name  = "/kubernetes/hbx-prd/np-api-gateway/REDIS_HOST"
  type  = "String"
  value = module.elasticache.replication_group_primary_endpoint_address
}

resource "aws_ssm_parameter" "redis_port" {
  name  = "/kubernetes/hbx-prd/np-api-gateway/REDIS_PORT"
  type  = "String"
  value = tostring(module.elasticache.replication_group_port)
}

resource "aws_ssm_parameter" "redis_tls" {
  name  = "/kubernetes/hbx-prd/np-api-gateway/REDIS_TLS"
  type  = "String"
  value = "true"
}
