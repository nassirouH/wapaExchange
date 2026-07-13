output "alb_dns_name" {
  description = "Point a Route53 ALIAS record at this for var.domain_name."
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  description = "Private RDS endpoint (only reachable from the VPC)."
  value       = module.database.endpoint
  sensitive   = true
}

output "redis_endpoint" {
  value     = module.cache.endpoint
  sensitive = true
}

output "kyc_bucket_name" {
  value = module.storage.bucket_name
}
