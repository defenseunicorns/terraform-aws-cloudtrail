################################################################################
# General
################################################################################
#region
variable "name" {
  description = "The name of the CloudTrail."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all taggable resources"
  type        = map(string)
  default     = {}
}
#endregion

################################################################################
# CloudTrail
################################################################################
#region
variable "enable_logging" {
  description = "Enables logging for the trail. Defaults to true."
  type        = bool
  default     = true
}

variable "is_organization_trail" {
  description = "Whether the trail is an AWS Organizations trail. Defaults to false."
  type        = bool
  default     = false
}

variable "s3_key_prefix" {
  description = "S3 key prefix that follows the name of the bucket designated for log file delivery."
  type        = string
  default     = "cloudtrail"
}

variable "sns_topic_name" {
  description = "Name of the Amazon SNS topic defined for notification of log file delivery."
  type        = string
  default     = null
}

variable "include_global_service_events" {
  description = "Specifies whether the trail is publishing events from global services such as IAM to the log files."
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Specifies whether the trail applies only to the current region or to all regions."
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Specifies whether log file integrity validation is enabled."
  type        = bool
  default     = true
}

variable "event_selectors" {
  description = <<-EOT
    Specifies an event selector for enabling data event logging. Fields include include_management_events, read_write_type, exclude_management_event_sources, and data_resources.
    See: https://www.terraform.io/docs/providers/aws/r/cloudtrail.html for details on this variable and https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_EventSelector.html for details on the underlying API.
  EOT
  type        = any
  # type = list(object({
  #   include_management_events        = bool
  #   read_write_type                  = string
  #   exclude_management_event_sources = list(string)
  #   data_resources = list(object({
  #     type   = string
  #     values = list(string)
  #   }))
  # }))
  default = []
}

variable "advanced_event_selectors" {
  description = <<-EOT
  Specifies an advanced event selector for fine-grained event logging. Includes name and field_selectors.
  See: https://www.terraform.io/docs/providers/aws/r/cloudtrail.html for details on this variable and https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_EventSelector.html for details on the underlying API.
  EOT
  type        = any
  # type = list(object({
  #   name = string
  #   field_selectors = list(object({
  #     field           = string
  #     equals          = list(string)
  #     not_equals      = list(string)
  #     starts_with     = list(string)
  #     ends_with       = list(string)
  #     not_starts_with = list(string)
  #     not_ends_with   = list(string)
  #   }))
  # }))
  default = []
}

variable "insight_selectors" {
  description = "List of insight types, such as ApiCallRateInsight and ApiErrorRateInsight, to log on the trail."
  type        = list(string)
  default     = []
}
#endregion

################################################################################
# KMS Key
################################################################################
#region
variable "create_kms_key" {
  description = "Determines whether to create a KMS key for encrypting CloudTrail logs. If not, an existing key ARN must be provided."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The KMS key ID to use for encrypting CloudTrail logs."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "The KMS key ARN to use for encrypting CloudTrail logs."
  type        = string
  default     = ""
}

variable "kms_key_description" {
  description = "The description of the key as viewed in AWS console"
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key. If you specify a value, it must be between `7` and `30`, inclusive. If you do not specify a value, it defaults to `30`"
  type        = number
  default     = null
}

variable "enable_kms_key_rotation" {
  description = "Specifies whether key rotation is enabled. Defaults to `true`"
  type        = bool
  default     = true
}

variable "kms_key_enable_default_policy" {
  description = "Specifies whether to enable the default key policy. Defaults to `false`"
  type        = bool
  default     = false
}

variable "kms_key_owners" {
  description = "A list of IAM ARNs for those who will have full key permissions (`kms:*`)"
  type        = list(string)
  default     = []
}

variable "kms_key_administrators" {
  description = "A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users)"
  type        = list(string)
  default     = []
}

variable "kms_key_service_users" {
  description = "A list of IAM ARNs for [key service users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-service-integration)"
  type        = list(string)
  default     = []
}

variable "kms_key_source_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s"
  type        = list(string)
  default     = []
}

variable "kms_key_override_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid`"
  type        = list(string)
  default     = []
}

variable "kms_key_aliases" {
  description = "A list of aliases to create. Note - due to the use of `toset()`, values must be static strings and not computed values"
  type        = list(string)
  default     = []
}

variable "kms_key_statements" {
  description = "A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type        = any
  default     = []
}
#endregion

################################################################################
# S3 Bucket
################################################################################
#region
variable "create_s3_bucket" {
  description = "Determines whether to create an S3 bucket for storing CloudTrail logs. If not, an existing bucket name must be provided."
  type        = bool
  default     = true
}

variable "s3_bucket_name_use_prefix" {
  description = "Determines whether to use the CloudTrail name as a prefix for the S3 bucket name."
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "The name of the existing S3 bucket to be used if 'create_s3_bucket' is set to false."
  type        = string
  default     = ""
}

variable "s3_bucket_name_prefix" {
  description = "The prefix to use for the S3 bucket name."
  type        = string
  default     = ""
}

variable "s3_bucket_force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  type        = bool
  default     = false
}

variable "attach_bucket_policy" {
  description = "Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy)"
  type        = bool
  default     = true
}

variable "bucket_policy" {
  description = "(Optional) A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide."
  type        = string
  default     = null
}

variable "attach_public_bucket_policy" {
  description = "Controls if S3 bucket should have public bucket policy attached (set to `true` to use value of `public_policy` as bucket policy)"
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "(Optional) Whether Amazon S3 should block public ACLs for this bucket. Defaults to true."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "(Optional) Whether Amazon S3 should block public bucket policies for this bucket. Defaults to true."
  type        = bool
  default     = true

}

variable "ignore_public_acls" {
  description = "(Optional) Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to true."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "(Optional) Whether Amazon S3 should restrict public bucket policies for this bucket. Defaults to true."
  type        = bool
  default     = true
}

variable "s3_bucket_versioning" {
  description = "Map containing versioning configuration."
  type        = map(string)
  default = {
    enabled    = false
    mfa_delete = false
  }
}

variable "s3_bucket_server_side_encryption_configuration" {
  description = "Map containing server-side encryption configuration."
  type        = any
  default     = {}
}

variable "enable_s3_bucket_server_side_encryption_configuration" {
  description = "Whether to enable server-side encryption configuration."
  type        = bool
  default     = true
}

variable "s3_bucket_lifecycle_rules" {
  description = "List of maps containing configuration of object lifecycle management."
  type        = any
  default = [
    {
      id                                     = "whatever"
      status                                 = "Enabled"
      abort_incomplete_multipart_upload_days = 7

      #see https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html#sc-compare
      # https://docs.aws.amazon.com/AmazonS3/latest/API/API_Transition.html
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        },
        {
          days          = 180
          storage_class = "DEEP_ARCHIVE"
        },
      ]

      expiration = {
        days = 365
      }
    }
  ]
}

#endregion

################################################################################
# CloudWatch
################################################################################
#region
variable "cloudwatch_logs_group_name" {
  description = "The name of the CloudWatch Log Group to which CloudTrail events will be delivered."
  type        = string
  default     = ""
}

variable "cloudwatch_logs_group_use_name_prefix" {
  description = "Determines whether to use the CloudTrail name as a prefix for the CloudWatch Log Group name."
  type        = bool
  default     = true
}

variable "cloudwatch_logs_group_name_prefix" {
  description = "The prefix to use for the CloudWatch Log Group name."
  type        = string
  default     = ""
}

variable "cloudwatch_logs_role_arn" {
  description = "The ARN of the role that the CloudTrail will assume to write to CloudWatch logs."
  type        = string
  default     = ""
}

variable "create_cloudwatch_logs_group" {
  description = "Determines whether to create a CloudWatch Log Group for CloudTrail logs. If not, an existing log group ARN must be provided."
  type        = bool
  default     = true
}

variable "cloudwatch_logs_group_arn" {
  description = "The ARN of the existing CloudWatch Log Group to be used if 'create_cloudwatch_log_group' is set to false."
  type        = string
  default     = ""
}

variable "cloudwatch_logs_group_retention_in_days" {
  description = "The number of days log events are kept in CloudWatch Logs. When an object expires, CloudWatch Logs automatically deletes it. If you don't specify a value, the default retention period is never expire."
  type        = number
  default     = 90
}

#endregion

################################################################################
# IAM
################################################################################
#region
variable "create_cloudtrail_iam_role" {
  description = "Determines whether to create an IAM role for the CloudTrail. If not, an existing role name must be provided."
  type        = bool
  default     = true

}

### role

variable "cloudtrail_iam_role_name_use_prefix" {
  description = "Determines whether to use the CloudTrail name as a prefix for the IAM role name."
  type        = bool
  default     = true
}

variable "cloudtrail_iam_role_name_prefix" {
  description = "The prefix to use for the IAM role name."
  type        = string
  default     = ""
}

variable "cloudtrail_iam_role_name" {
  description = "The name of the IAM role to be created for the CloudTrail to send logs to CloudWatch."
  type        = string
  default     = ""
}

### policy

variable "cloudtrail_iam_policy_name_use_prefix" {
  description = "Determines whether to use the CloudTrail name as a prefix for the IAM policy name."
  type        = bool
  default     = true
}

variable "cloudtrail_iam_policy_name_prefix" {
  description = "The prefix to use for the IAM policy name."
  type        = string
  default     = ""
}

variable "cloudtrail_iam_policy_name" {
  description = "The name of the IAM policy to be created for the CloudTrail to send logs to CloudWatch."
  type        = string
  default     = ""
}
#endregion
