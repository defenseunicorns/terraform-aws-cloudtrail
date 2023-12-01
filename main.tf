################################################################################
# General
################################################################################
#region
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}
#endregion

################################################################################
# S3 Bucket
################################################################################
#region

locals {
  s3_bucket_name        = coalesce(var.s3_bucket_name, "${var.name}-cloudtrail")
  s3_bucket_name_prefix = coalesce(var.s3_bucket_name_prefix, "${var.name}-cloudtrail-")
  bucket_policy         = coalesce(var.bucket_policy, data.aws_iam_policy_document.this.json)

  # local.kms_master_key_id sets KMS encryption: uses custom config if provided, else defaults to module's key or specified kms_key_id, and is null if encryption is disabled.
  kms_master_key_id = var.create_kms_key && length(var.kms_key_id) == 0 ? try(module.kms.key_id, null) : var.kms_key_id

  # If enable_s3_bucket_server_side_encryption_configuration is true:
  # - If a custom encryption configuration (var.s3_bucket_server_side_encryption_configuration) is provided and not empty, use this configuration.
  # - Else, if local.kms_master_key_id is not null:
  # - Set encryption to use AWS KMS with local.kms_master_key_id.
  # - Else (if local.kms_master_key_id is null):
  # - Do not set any encryption configuration (results in null).
  # Else (if enable_s3_bucket_server_side_encryption_configuration is false):
  # - Do not set any encryption configuration (results in null).
  s3_bucket_server_side_encryption_configuration = var.enable_s3_bucket_server_side_encryption_configuration ? (
    length(var.s3_bucket_server_side_encryption_configuration) > 0 ?
    var.s3_bucket_server_side_encryption_configuration :
    (local.kms_master_key_id != null ? <<-EOT
    {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = "aws:kms"
          kms_master_key_id = ${local.kms_master_key_id}
        }
      }
    }
    EOT
    : null)
  ) : null
}

data "aws_iam_policy_document" "this" {
  count = var.create_s3_bucket ? 0 : 1
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[0].arn}/${var.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.name}"]
    }
  }
}

module "s3_bucket" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v3.8.2"

  bucket        = var.s3_bucket_name_use_prefix ? null : local.s3_bucket_name
  bucket_prefix = var.s3_bucket_name_use_prefix ? local.s3_bucket_name_prefix : null

  attach_policy = var.attach_bucket_policy
  policy        = local.bucket_policy

  attach_public_policy                 = var.attach_public_bucket_policy
  block_public_acls                    = var.block_public_acls
  block_public_policy                  = var.block_public_policy
  ignore_public_acls                   = var.ignore_public_acls
  restrict_public_buckets              = var.restrict_public_buckets
  versioning                           = var.s3_bucket_versioning
  server_side_encryption_configuration = local.s3_bucket_server_side_encryption_configuration
  lifecycle_rule                       = var.s3_bucket_lifecycle_rules

  tags = var.tags
}


#endregion

################################################################################
# IAM
################################################################################
#region
# This section is used for allowing CloudTrail to send logs to CloudWatch.

locals {
  cloudtrail_iam_role_name   = coalesce(var.cloudtrail_iam_role_name, "${var.name}-cloudtrail-to-cloudwatch")
  cloudtrail_iam_policy_name = coalesce(var.cloudtrail_iam_policy_name, "${var.name}-cloudtrail-to-cloudwatch")

  cloudtrail_iam_role_name_prefix   = coalesce(var.cloudtrail_iam_role_name_prefix, "${var.name}-cloudtrail-role")
  cloudtrail_iam_policy_name_prefix = coalesce(var.cloudtrail_iam_policy_name_prefix, "${var.name}-cloudtrail-policy")
}

# This policy allows the CloudTrail service for any account to assume this role.
data "aws_iam_policy_document" "cloudtrail_assume_role" {
  count = var.create_cloudtrail_iam_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

# This role is used by CloudTrail to send logs to CloudWatch.
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  count = var.create_cloudtrail_iam_role ? 1 : 0

  name               = var.cloudtrail_iam_role_name_use_prefix ? null : local.cloudtrail_iam_role_name
  name_prefix        = var.cloudtrail_iam_role_name_use_prefix ? local.cloudtrail_iam_role_name_prefix : null
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  count = var.create_cloudtrail_iam_role ? 1 : 0
  statement {
    sid = "WriteCloudWatchLogs"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${module.cloudwatch_logs_group.cloudwatch_log_group_name}:*"]
  }
}

resource "aws_iam_policy" "cloudtrail_cloudwatch_logs" {
  count = var.create_cloudtrail_iam_role ? 1 : 0

  name        = var.cloudtrail_iam_policy_name_use_prefix ? null : local.cloudtrail_iam_policy_name
  name_prefix = var.cloudtrail_iam_policy_name_use_prefix ? local.cloudtrail_iam_policy_name_prefix : null
  policy      = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}

resource "aws_iam_policy_attachment" "main" {
  count = var.create_cloudtrail_iam_role ? 1 : 0

  name       = "${var.cloudtrail_iam_policy_name}-attachment"
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch_logs.arn
  roles      = [aws_iam_role.cloudtrail_cloudwatch_role.name]
}
#endregion

################################################################################
# CloudWatch Log Group
################################################################################
#region
locals {
  cloudwatch_logs_group_name        = coalesce(var.cloudwatch_logs_group_name, "${var.name}-cloudtrail")
  cloudwatch_logs_group_name_prefix = coalesce(var.cloudwatch_logs_group_name_prefix, "${var.name}-cloudtrail-")
}

module "cloudwatch_logs_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=v4.3.0"

  create = var.create_cloudwatch_logs_group && length(var.cloudwatch_logs_group_arn) == 0

  name              = var.cloudwatch_logs_group_use_name_prefix ? null : local.cloudwatch_logs_group_name
  name_prefix       = var.cloudwatch_logs_group_use_name_prefix ? local.cloudwatch_logs_group_name_prefix : null
  retention_in_days = var.cloudwatch_logs_group_retention_in_days
  kms_key_id        = coalesce(var.kms_key_id, module.kms.key_id)

  tags = var.tags
}
#endregion

################################################################################
# KMS Key
################################################################################
#region
locals {
  # token from: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/default-kms-key-policy.html and other sources
  key_statements = [
    {
      sid     = "Enable IAM User Permissions"
      effect  = "Allow"
      actions = ["kms:*"]
      principals = {
        type        = "AWS"
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      resources = ["*"]
    },
    {
      sid     = "Allow CloudTrail to encrypt logs"
      effect  = "Allow"
      actions = ["kms:GenerateDataKey*"]
      principals = {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      resources = ["*"]
      condition = {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
      }
    },
    {
      sid     = "Allow CloudTrail to describe key"
      effect  = "Allow"
      actions = ["kms:DescribeKey"]
      principals = {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      resources = ["*"]
    },
    {
      sid     = "Allow principals in the account to decrypt log files"
      effect  = "Allow"
      actions = ["kms:Decrypt", "kms:ReEncryptFrom"]
      principals = {
        type        = "AWS"
        identifiers = ["*"]
      }
      resources = ["*"]
      condition = {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
      condition = {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
      }
    },
    {
      sid     = "Allow alias creation during setup"
      effect  = "Allow"
      actions = ["kms:CreateAlias"]
      principals = {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition = {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
      }
      condition = {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
      resources = ["*"]
    },
    {
      sid     = "Enable cross account log decryption"
      effect  = "Allow"
      actions = ["kms:Decrypt", "kms:ReEncryptFrom"]
      principals = {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition = {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
      condition = {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
      }
      resources = ["*"]
    },
    {
      sid    = "Allow logs KMS access"
      effect = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
      }
      actions   = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
      resources = ["*"]
    },
    {
      sid    = "Allow Cloudtrail to decrypt and generate key for sns access"
      effect = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      actions   = ["kms:Decrypt*", "kms:GenerateDataKey*"]
      resources = ["*"]
    }
  ]
}

module "kms" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=v2.1.0"

  create = var.create_kms_key && length(var.kms_key_id) == 0

  description             = coalesce(var.kms_key_description, "${var.name} cloudtrail encryption key")
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  # Policy
  enable_default_policy     = var.kms_key_enable_default_policy
  key_owners                = var.kms_key_owners
  key_administrators        = coalescelist(var.kms_key_administrators, [data.aws_iam_session_context.current.issuer_arn])
  key_users                 = coalescelist(var.kms_key_users, [data.aws_iam_session_context.current.issuer_arn])
  key_service_users         = var.kms_key_service_users
  source_policy_documents   = var.kms_key_source_policy_documents
  override_policy_documents = var.kms_key_override_policy_documents
  key_statements            = coalescelist(var.key_statements, local.key_statements)

  # Aliases
  aliases = var.kms_key_aliases
  computed_aliases = {
    # Computed since users can pass in computed values for cluster name such as random provider resources
    cluster = { name = "cloudtrail/${var.name}" }
  }

  tags = var.tags
}
#endregion

################################################################################
# CloudTrail
################################################################################
#region
resource "aws_cloudtrail" "this" {
  # checkov:skip=CKV_AWS_252: "Ensure CloudTrail defines an SNS Topic"
  # checkov:skip=CKV2_AWS_10
  name                          = var.name
  s3_bucket_name                = coalesce(var.s3_bucket_name, module.s3_bucket.s3_bucket_id)
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = var.enable_log_file_validation
  cloud_watch_logs_role_arn     = coalesce(var.cloudwatch_logs_role_arn, aws_iam_role.cloudtrail_cloudwatch_role.arn)
  cloud_watch_logs_group_arn    = coalesce(var.cloud_watch_logs_group_arn, "${module.cloudwatch_logs_group.cloudwatch_log_group_arn}:*") # CloudTrail requires the Log Stream wildcard
  kms_key_id                    = coalesce(var.kms_key_id, module.kms.key_id)
  enable_logging                = var.enable_logging
  is_organization_trail         = var.is_organization_trail
  s3_key_prefix                 = var.s3_key_prefix
  sns_topic_name                = var.sns_topic_name
  tags                          = var.tags

  dynamic "event_selector" {
    for_each = var.event_selectors
    content {
      include_management_events        = lookup(event_selector.value, "include_management_events", null)
      read_write_type                  = lookup(event_selector.value, "read_write_type", null)
      exclude_management_event_sources = lookup(event_selector.value, "exclude_management_event_sources", null)
      dynamic "data_resource" {
        for_each = lookup(event_selector.value, "data_resources", [])
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  dynamic "advanced_event_selector" {
    for_each = var.advanced_event_selectors
    content {
      name = advanced_event_selector.value.name
      dynamic "field_selector" {
        for_each = lookup(advanced_event_selector.value, "field_selectors", [])
        content {
          field           = field_selector.value.field
          equals          = lookup(field_selector.value, "equals", null)
          not_equals      = lookup(field_selector.value, "not_equals", null)
          starts_with     = lookup(field_selector.value, "starts_with", null)
          ends_with       = lookup(field_selector.value, "ends_with", null)
          not_starts_with = lookup(field_selector.value, "not_starts_with", null)
          not_ends_with   = lookup(field_selector.value, "not_ends_with", null)
        }
      }
    }
  }

  dynamic "insight_selector" {
    for_each = var.insight_selectors
    content {
      insight_type = insight_selector.value
    }
  }
}
#endregion
