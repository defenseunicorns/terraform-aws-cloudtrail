# terraform-aws-cloudtrail

Terraform module to provision [CloudTrail](https://aws.amazon.com/cloudtrail/) on AWS.

## Notes

* This module should be used when bootstrapping a new AWS account, to set up a CloudTrail that monitors the activity in the account. It is not meant to be used as part of every terraform deployment in the account.
* See [CloudTrail Best Practices](https://aws.amazon.com/blogs/mt/aws-cloudtrail-best-practices/) for more information on how to configure CloudTrail.
* Provides the choice for the user to either provide an S3 bucket or create a new one with sensible defaults.
* Simplifies the creation of the CloudTrail by using opinionated configuration. If you need more customizability please open an issue so we can add it.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.62.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.62.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch_logs_group"></a> [cloudwatch\_logs\_group](#module\_cloudwatch\_logs\_group) | git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group | v5.3.1 |
| <a name="module_kms"></a> [kms](#module\_kms) | git::https://github.com/terraform-aws-modules/terraform-aws-kms.git | v3.0.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git | v4.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_iam_policy.cloudtrail_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudtrail_cloudwatch_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudtrail_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_event_selectors"></a> [advanced\_event\_selectors](#input\_advanced\_event\_selectors) | Specifies an advanced event selector for fine-grained event logging. Includes name and field\_selectors.<br>See: https://www.terraform.io/docs/providers/aws/r/cloudtrail.html for details on this variable and https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_EventSelector.html for details on the underlying API. | `any` | `[]` | no |
| <a name="input_attach_bucket_policy"></a> [attach\_bucket\_policy](#input\_attach\_bucket\_policy) | Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy) | `bool` | `true` | no |
| <a name="input_attach_public_bucket_policy"></a> [attach\_public\_bucket\_policy](#input\_attach\_public\_bucket\_policy) | Controls if S3 bucket should have public bucket policy attached (set to `true` to use value of `public_policy` as bucket policy) | `bool` | `true` | no |
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | (Optional) Whether Amazon S3 should block public ACLs for this bucket. Defaults to true. | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | (Optional) Whether Amazon S3 should block public bucket policies for this bucket. Defaults to true. | `bool` | `true` | no |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | (Optional) A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide. | `string` | `null` | no |
| <a name="input_cloudtrail_iam_policy_name"></a> [cloudtrail\_iam\_policy\_name](#input\_cloudtrail\_iam\_policy\_name) | The name of the IAM policy to be created for the CloudTrail to send logs to CloudWatch. | `string` | `""` | no |
| <a name="input_cloudtrail_iam_policy_name_prefix"></a> [cloudtrail\_iam\_policy\_name\_prefix](#input\_cloudtrail\_iam\_policy\_name\_prefix) | The prefix to use for the IAM policy name. | `string` | `""` | no |
| <a name="input_cloudtrail_iam_policy_name_use_prefix"></a> [cloudtrail\_iam\_policy\_name\_use\_prefix](#input\_cloudtrail\_iam\_policy\_name\_use\_prefix) | Determines whether to use the CloudTrail name as a prefix for the IAM policy name. | `bool` | `true` | no |
| <a name="input_cloudtrail_iam_role_name"></a> [cloudtrail\_iam\_role\_name](#input\_cloudtrail\_iam\_role\_name) | The name of the IAM role to be created for the CloudTrail to send logs to CloudWatch. | `string` | `""` | no |
| <a name="input_cloudtrail_iam_role_name_prefix"></a> [cloudtrail\_iam\_role\_name\_prefix](#input\_cloudtrail\_iam\_role\_name\_prefix) | The prefix to use for the IAM role name. | `string` | `""` | no |
| <a name="input_cloudtrail_iam_role_name_use_prefix"></a> [cloudtrail\_iam\_role\_name\_use\_prefix](#input\_cloudtrail\_iam\_role\_name\_use\_prefix) | Determines whether to use the CloudTrail name as a prefix for the IAM role name. | `bool` | `true` | no |
| <a name="input_cloudwatch_logs_group_arn"></a> [cloudwatch\_logs\_group\_arn](#input\_cloudwatch\_logs\_group\_arn) | The ARN of the existing CloudWatch Log Group to be used if 'create\_cloudwatch\_log\_group' is set to false. | `string` | `""` | no |
| <a name="input_cloudwatch_logs_group_name"></a> [cloudwatch\_logs\_group\_name](#input\_cloudwatch\_logs\_group\_name) | The name of the CloudWatch Log Group to which CloudTrail events will be delivered. | `string` | `""` | no |
| <a name="input_cloudwatch_logs_group_name_prefix"></a> [cloudwatch\_logs\_group\_name\_prefix](#input\_cloudwatch\_logs\_group\_name\_prefix) | The prefix to use for the CloudWatch Log Group name. | `string` | `""` | no |
| <a name="input_cloudwatch_logs_group_retention_in_days"></a> [cloudwatch\_logs\_group\_retention\_in\_days](#input\_cloudwatch\_logs\_group\_retention\_in\_days) | The number of days log events are kept in CloudWatch Logs. When an object expires, CloudWatch Logs automatically deletes it. If you don't specify a value, the default retention period is never expire. | `number` | `90` | no |
| <a name="input_cloudwatch_logs_group_use_name_prefix"></a> [cloudwatch\_logs\_group\_use\_name\_prefix](#input\_cloudwatch\_logs\_group\_use\_name\_prefix) | Determines whether to use the CloudTrail name as a prefix for the CloudWatch Log Group name. | `bool` | `true` | no |
| <a name="input_cloudwatch_logs_role_arn"></a> [cloudwatch\_logs\_role\_arn](#input\_cloudwatch\_logs\_role\_arn) | The ARN of the role that the CloudTrail will assume to write to CloudWatch logs. | `string` | `""` | no |
| <a name="input_create_cloudtrail_iam_role"></a> [create\_cloudtrail\_iam\_role](#input\_create\_cloudtrail\_iam\_role) | Determines whether to create an IAM role for the CloudTrail. If not, an existing role name must be provided. | `bool` | `true` | no |
| <a name="input_create_cloudwatch_logs_group"></a> [create\_cloudwatch\_logs\_group](#input\_create\_cloudwatch\_logs\_group) | Determines whether to create a CloudWatch Log Group for CloudTrail logs. If not, an existing log group ARN must be provided. | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Determines whether to create a KMS key for encrypting CloudTrail logs. If not, an existing key ARN must be provided. | `bool` | `true` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | Determines whether to create an S3 bucket for storing CloudTrail logs. If not, an existing bucket name must be provided. | `bool` | `true` | no |
| <a name="input_enable_kms_key_rotation"></a> [enable\_kms\_key\_rotation](#input\_enable\_kms\_key\_rotation) | Specifies whether key rotation is enabled. Defaults to `true` | `bool` | `true` | no |
| <a name="input_enable_log_file_validation"></a> [enable\_log\_file\_validation](#input\_enable\_log\_file\_validation) | Specifies whether log file integrity validation is enabled. | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enables logging for the trail. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_s3_bucket_server_side_encryption_configuration"></a> [enable\_s3\_bucket\_server\_side\_encryption\_configuration](#input\_enable\_s3\_bucket\_server\_side\_encryption\_configuration) | Whether to enable server-side encryption configuration. | `bool` | `true` | no |
| <a name="input_event_selectors"></a> [event\_selectors](#input\_event\_selectors) | Specifies an event selector for enabling data event logging. Fields include include\_management\_events, read\_write\_type, exclude\_management\_event\_sources, and data\_resources.<br>See: https://www.terraform.io/docs/providers/aws/r/cloudtrail.html for details on this variable and https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_EventSelector.html for details on the underlying API. | `any` | `[]` | no |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | (Optional) Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to true. | `bool` | `true` | no |
| <a name="input_include_global_service_events"></a> [include\_global\_service\_events](#input\_include\_global\_service\_events) | Specifies whether the trail is publishing events from global services such as IAM to the log files. | `bool` | `true` | no |
| <a name="input_insight_selectors"></a> [insight\_selectors](#input\_insight\_selectors) | List of insight types, such as ApiCallRateInsight and ApiErrorRateInsight, to log on the trail. | `list(string)` | `[]` | no |
| <a name="input_is_multi_region_trail"></a> [is\_multi\_region\_trail](#input\_is\_multi\_region\_trail) | Specifies whether the trail applies only to the current region or to all regions. | `bool` | `true` | no |
| <a name="input_is_organization_trail"></a> [is\_organization\_trail](#input\_is\_organization\_trail) | Whether the trail is an AWS Organizations trail. Defaults to false. | `bool` | `false` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available | `list(string)` | `[]` | no |
| <a name="input_kms_key_aliases"></a> [kms\_key\_aliases](#input\_kms\_key\_aliases) | A list of aliases to create. Note - due to the use of `toset()`, values must be static strings and not computed values | `list(string)` | `[]` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The KMS key ARN to use for encrypting CloudTrail logs. | `string` | `""` | no |
| <a name="input_kms_key_deletion_window_in_days"></a> [kms\_key\_deletion\_window\_in\_days](#input\_kms\_key\_deletion\_window\_in\_days) | The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key. If you specify a value, it must be between `7` and `30`, inclusive. If you do not specify a value, it defaults to `30` | `number` | `null` | no |
| <a name="input_kms_key_description"></a> [kms\_key\_description](#input\_kms\_key\_description) | The description of the key as viewed in AWS console | `string` | `null` | no |
| <a name="input_kms_key_enable_default_policy"></a> [kms\_key\_enable\_default\_policy](#input\_kms\_key\_enable\_default\_policy) | Specifies whether to enable the default key policy. Defaults to `false` | `bool` | `false` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | The KMS key ID to use for encrypting CloudTrail logs. | `string` | `""` | no |
| <a name="input_kms_key_override_policy_documents"></a> [kms\_key\_override\_policy\_documents](#input\_kms\_key\_override\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| <a name="input_kms_key_owners"></a> [kms\_key\_owners](#input\_kms\_key\_owners) | A list of IAM ARNs for those who will have full key permissions (`kms:*`) | `list(string)` | `[]` | no |
| <a name="input_kms_key_service_users"></a> [kms\_key\_service\_users](#input\_kms\_key\_service\_users) | A list of IAM ARNs for [key service users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-service-integration) | `list(string)` | `[]` | no |
| <a name="input_kms_key_source_policy_documents"></a> [kms\_key\_source\_policy\_documents](#input\_kms\_key\_source\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| <a name="input_kms_key_statements"></a> [kms\_key\_statements](#input\_kms\_key\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `[]` | no |
| <a name="input_kms_key_users"></a> [kms\_key\_users](#input\_kms\_key\_users) | A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users) | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the CloudTrail. | `string` | n/a | yes |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | (Optional) Whether Amazon S3 should restrict public bucket policies for this bucket. Defaults to true. | `bool` | `true` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_s3_bucket_lifecycle_rules"></a> [s3\_bucket\_lifecycle\_rules](#input\_s3\_bucket\_lifecycle\_rules) | List of maps containing configuration of object lifecycle management. | `any` | <pre>[<br>  {<br>    "abort_incomplete_multipart_upload_days": 7,<br>    "expiration": {<br>      "days": 365<br>    },<br>    "id": "whatever",<br>    "status": "Enabled",<br>    "transition": [<br>      {<br>        "days": 30,<br>        "storage_class": "STANDARD_IA"<br>      },<br>      {<br>        "days": 60,<br>        "storage_class": "GLACIER"<br>      },<br>      {<br>        "days": 180,<br>        "storage_class": "DEEP_ARCHIVE"<br>      }<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name of the existing S3 bucket to be used if 'create\_s3\_bucket' is set to false. | `string` | `""` | no |
| <a name="input_s3_bucket_name_prefix"></a> [s3\_bucket\_name\_prefix](#input\_s3\_bucket\_name\_prefix) | The prefix to use for the S3 bucket name. | `string` | `""` | no |
| <a name="input_s3_bucket_name_use_prefix"></a> [s3\_bucket\_name\_use\_prefix](#input\_s3\_bucket\_name\_use\_prefix) | Determines whether to use the CloudTrail name as a prefix for the S3 bucket name. | `bool` | `true` | no |
| <a name="input_s3_bucket_server_side_encryption_configuration"></a> [s3\_bucket\_server\_side\_encryption\_configuration](#input\_s3\_bucket\_server\_side\_encryption\_configuration) | Map containing server-side encryption configuration. | `any` | `{}` | no |
| <a name="input_s3_bucket_versioning"></a> [s3\_bucket\_versioning](#input\_s3\_bucket\_versioning) | Map containing versioning configuration. | `map(string)` | <pre>{<br>  "enabled": false,<br>  "mfa_delete": false<br>}</pre> | no |
| <a name="input_s3_key_prefix"></a> [s3\_key\_prefix](#input\_s3\_key\_prefix) | S3 key prefix that follows the name of the bucket designated for log file delivery. | `string` | `"cloudtrail"` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Name of the Amazon SNS topic defined for notification of log file delivery. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all taggable resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudtrail_arn"></a> [cloudtrail\_arn](#output\_cloudtrail\_arn) | ARN of the cloudtrail |
| <a name="output_cloudtrail_home_region"></a> [cloudtrail\_home\_region](#output\_cloudtrail\_home\_region) | The region in which the cloudtrail was created |
| <a name="output_cloudtrail_id"></a> [cloudtrail\_id](#output\_cloudtrail\_id) | The name of the cloudtrail |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch log group. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group. |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the bucket. |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | The name of the bucket. |
| <a name="output_s3_bucket_region"></a> [s3\_bucket\_region](#output\_s3\_bucket\_region) | The AWS region this bucket resides in. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
