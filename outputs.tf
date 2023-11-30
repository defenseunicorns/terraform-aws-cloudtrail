output "cloudtrail_arn" {
  value       = aws_cloudtrail.this.arn
  description = "ARN of the cloudtrail"
}

output "cloudtrail_home_region" {
  value       = aws_cloudtrail.this.home_region
  description = "The region in which the cloudtrail was created"
}

output "cloudtrail_id" {
  value       = aws_cloudtrail.this.id
  description = "The name of the cloudtrail"
}
