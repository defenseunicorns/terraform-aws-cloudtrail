################################################################################
# CloudTrail
################################################################################
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


################################################################################
# S3 Bucket
################################################################################

output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = try(module.s3_bucket.s3_bucket_id, "")
}

output "s3_bucket_arn" {
  description = "The ARN of the bucket."
  value       = try(module.s3_bucket.s3_bucket_arn, "")
}

output "s3_bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = try(module.s3_bucket.s3_bucket_region, "")
}

################################################################################
# CloudWatch Logs
################################################################################

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group."
  value       = try(module.cloudwatch_logs_group.cloudwatch_log_group_arn, "")
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group."
  value       = try(module.cloudwatch_logs_group.cloudwatch_log_group_name, "")
}
