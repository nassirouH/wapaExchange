locals {
  name = "${var.project}-${var.environment}"
}

module "network" {
  source = "../../modules/network"
  name   = local.name
  cidr   = "10.20.0.0/16"
  azs    = ["eu-west-3a", "eu-west-3b"]
}

module "database" {
  source             = "../../modules/database"
  name               = local.name
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  app_security_group = module.network.app_security_group_id
  db_password        = var.db_password
}

module "cache" {
  source             = "../../modules/cache"
  name               = local.name
  subnet_ids         = module.network.private_subnet_ids
  vpc_id             = module.network.vpc_id
  app_security_group = module.network.app_security_group_id
}

module "storage" {
  source = "../../modules/storage"
  name   = local.name
}

module "ecs" {
  source                = "../../modules/ecs"
  name                  = local.name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  app_security_group_id = module.network.app_security_group_id
  alb_security_group_id = module.network.alb_security_group_id
  container_image       = var.container_image
  acm_certificate_arn   = var.acm_certificate_arn
  database_url_secret   = module.database.connection_secret_arn
  redis_url_secret      = module.cache.connection_secret_arn
  kyc_bucket_arn        = module.storage.bucket_arn
  cors_origin           = var.cors_origin
}
