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
  s3_bucket_name        = try(coalesce(var.s3_bucket_name, "${var.name}-cloudtrail"), null)
  s3_bucket_name_prefix = try(coalesce(var.s3_bucket_name_prefix, "${var.name}-cloudtrail-"), null)
  bucket_policy         = try(coalesce(var.bucket_policy, data.aws_iam_policy_document.s3_bucket[0].json), null)

  # local.kms_master_key_id sets KMS encryption: uses custom config if provided, else defaults to module's key or specified kms_key_id, and is null if encryption is disabled.
  kms_master_key_id = var.create_kms_key ? module.kms.key_id : var.kms_key_id
  default_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = local.kms_master_key_id
      }
    }
  }

  s3_bucket_server_side_encryption_configuration = var.enable_s3_bucket_server_side_encryption_configuration ? coalesce(var.s3_bucket_server_side_encryption_configuration, local.default_encryption_configuration) : null
}

data "aws_iam_policy_document" "s3_bucket" {
  count = var.create_s3_bucket ? 1 : 0
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [module.s3_bucket.s3_bucket_arn]

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
    resources = ["${module.s3_bucket.s3_bucket_arn}/${var.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v4.1.1"

  create_bucket = var.create_s3_bucket

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
  force_destroy                        = var.s3_bucket_force_destroy

  tags = var.tags
}


#endregion

################################################################################
# IAM
################################################################################
#region
# This section is used for allowing CloudTrail to send logs to CloudWatch.

locals {
  cloudtrail_iam_role_name   = try(coalesce(var.cloudtrail_iam_role_name, "${var.name}-cloudtrail-to-cloudwatch"), null)
  cloudtrail_iam_policy_name = try(coalesce(var.cloudtrail_iam_policy_name, "${var.name}-cloudtrail-to-cloudwatch"), null)

  cloudtrail_iam_role_name_prefix   = try(coalesce(var.cloudtrail_iam_role_name_prefix, "${var.name}-cloudtrail-role"), null)
  cloudtrail_iam_policy_name_prefix = try(coalesce(var.cloudtrail_iam_policy_name_prefix, "${var.name}-cloudtrail-policy"), null)
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
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role[0].json
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
  policy      = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs[0].json
}

resource "aws_iam_policy_attachment" "main" {
  count = var.create_cloudtrail_iam_role ? 1 : 0

  name       = "${var.cloudtrail_iam_policy_name}-attachment"
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch_logs[0].arn
  roles      = [aws_iam_role.cloudtrail_cloudwatch_role[0].name]
}
#endregion

################################################################################
# CloudWatch Log Group
################################################################################
#region
locals {
  cloudwatch_logs_group_name        = try(coalesce(var.cloudwatch_logs_group_name, "${var.name}-cloudtrail"), null)
  cloudwatch_logs_group_name_prefix = try(coalesce(var.cloudwatch_logs_group_name_prefix, "${var.name}-cloudtrail-"), null)
}

module "cloudwatch_logs_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=v5.3.1"

  create = var.create_cloudwatch_logs_group && length(var.cloudwatch_logs_group_arn) == 0

  name              = var.cloudwatch_logs_group_use_name_prefix ? null : local.cloudwatch_logs_group_name
  name_prefix       = var.cloudwatch_logs_group_use_name_prefix ? local.cloudwatch_logs_group_name_prefix : null
  retention_in_days = var.cloudwatch_logs_group_retention_in_days
  kms_key_id        = try(coalesce(var.kms_key_arn, module.kms.key_arn), "")

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
      sid       = "Enable IAM User Permissions"
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
      ]
    },
    {
      sid     = "Allow CloudTrail to encrypt logs"
      effect  = "Allow"
      actions = ["kms:GenerateDataKey*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
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
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      resources = ["*"]
    },
    {
      sid     = "Allow principals in the account to decrypt log files"
      effect  = "Allow"
      actions = ["kms:Decrypt", "kms:ReEncryptFrom"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
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
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
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
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
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
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
      actions   = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
      resources = ["*"]
    },
    {
      sid    = "Allow Cloudtrail to decrypt and generate key for sns access"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      actions   = ["kms:Decrypt*", "kms:GenerateDataKey*"]
      resources = ["*"]
    }
  ]

  kms_key_description    = try(coalesce(var.kms_key_description, "${var.name} cloudtrail encryption key"), null)
  kms_key_administrators = try(coalescelist(var.kms_key_administrators, [data.aws_iam_session_context.current.issuer_arn]), [])
  kms_key_users          = try(coalescelist(var.kms_key_users, [data.aws_iam_session_context.current.issuer_arn]), [])
  kms_key_statements     = try(coalescelist(var.kms_key_statements, local.key_statements), [])
}

module "kms" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=v2.2.1"

  create = var.create_kms_key

  description             = local.kms_key_description
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  # Policy
  enable_default_policy     = var.kms_key_enable_default_policy
  key_owners                = var.kms_key_owners
  key_administrators        = local.kms_key_administrators
  key_users                 = local.kms_key_users
  key_service_users         = var.kms_key_service_users
  source_policy_documents   = var.kms_key_source_policy_documents
  override_policy_documents = var.kms_key_override_policy_documents
  key_statements            = local.kms_key_statements

  # Aliases
  aliases = var.kms_key_aliases
  computed_aliases = {
    # Computed since users can pass in computed values for cloudtrail name such as random provider resources
    cloudtrail = { name = "cloudtrail/${var.name}" }
  }

  tags = var.tags
}
#endregion

################################################################################
# CloudTrail
################################################################################
#region

locals {
  cloudtrail_s3_bucket_name             = try(coalesce(var.s3_bucket_name, module.s3_bucket.s3_bucket_id), null)
  cloudtrail_cloud_watch_logs_role_arn  = try(coalesce(var.cloudwatch_logs_role_arn, aws_iam_role.cloudtrail_cloudwatch_role[0].arn), null)
  cloudtrail_cloud_watch_logs_group_arn = try(coalesce(var.cloudwatch_logs_group_arn, "${module.cloudwatch_logs_group.cloudwatch_log_group_arn}:*"), null) # CloudTrail requires the Log Stream wildcard
  cloudtrail_kms_key_id                 = try(coalesce(var.kms_key_arn, module.kms.key_arn), null)
}

resource "aws_cloudtrail" "this" {
  # checkov:skip=CKV_AWS_252: "Ensure CloudTrail defines an SNS Topic"
  # checkov:skip=CKV2_AWS_10
  name                          = var.name
  s3_bucket_name                = local.cloudtrail_s3_bucket_name
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = var.enable_log_file_validation
  cloud_watch_logs_role_arn     = local.cloudtrail_cloud_watch_logs_role_arn
  cloud_watch_logs_group_arn    = local.cloudtrail_cloud_watch_logs_group_arn
  kms_key_id                    = local.cloudtrail_kms_key_id
  enable_logging                = var.enable_logging
  is_organization_trail         = var.is_organization_trail
  s3_key_prefix                 = var.s3_key_prefix
  sns_topic_name                = var.sns_topic_name

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

  tags = var.tags
}
#endregion
