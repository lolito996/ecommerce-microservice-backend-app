# Variables
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    api_gateway      = aws_ecr_repository.api_gateway.repository_url
    proxy_client     = aws_ecr_repository.proxy_client.repository_url
    user_service     = aws_ecr_repository.user_service.repository_url
    product_service  = aws_ecr_repository.product_service.repository_url
    order_service    = aws_ecr_repository.order_service.repository_url
    payment_service  = aws_ecr_repository.payment_service.repository_url
    shipping_service = aws_ecr_repository.shipping_service.repository_url
    favourite_service = aws_ecr_repository.favourite_service.repository_url
    service_discovery = aws_ecr_repository.service_discovery.repository_url
    cloud_config     = aws_ecr_repository.cloud_config.repository_url
  }
}
