output "alb_dns_name" {
  description = "Public entry point for the API"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "Where CI pushes images"
  value       = aws_ecr_repository.api.repository_url
}

output "db_endpoint" {
  description = "RDS endpoint (private, app subnets only)"
  value       = aws_db_instance.main.address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB master credentials"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
