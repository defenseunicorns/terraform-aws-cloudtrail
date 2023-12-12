data "aws_partition" "current" {}

resource "random_id" "default" {
  byte_length = 2
}


locals {
  # Add randomness to names to avoid collisions when multiple users are using this example
  cloudtrail_name = "${var.name_prefix}${lower(random_id.default.hex)}"
  tags = merge(
    var.tags,
    {
      RootTFModule = replace(basename(path.cwd), "_", "-") # tag names based on the directory name
      ManagedBy    = "Terraform"
      Repo         = "https://github.com/defenseunicorns/terraform-aws-cloudtrail"
    }
  )
}

module "cloudtrail" {
  source = "../.."

  name = local.cloudtrail_name

  create_s3_bucket        = true
  attach_bucket_policy    = true
  s3_bucket_force_destroy = true

  create_cloudwatch_logs_group = true
  create_kms_key               = true

  # see https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html
  event_selectors = [
    {
      # Include management events to capture all actions performed by AWS Management Console, AWS SDKs, command line tools, and other AWS services
      include_management_events = true

      # Capture both Read and Write API calls
      read_write_type = "All"

      # Exclude events from KMS service
      exclude_management_event_sources = ["kms.amazonaws.com"]

      data_resources = [
        # Logging Individual S3 Bucket Events By Using Basic Event Selectors
        {
          # Specify the type of data resource
          type = "AWS::S3::Object"

          # Specify the ARN of the S3 bucket and prefix
          values = ["arn:${data.aws_partition.current.partition}:s3:::terraform-state/"]
        },
      ]
    },
    {
      include_management_events = true
      read_write_type           = "All"

      data_resources = [
        {
          type = "AWS::Lambda::Function"
          # Logging Data Events for all Lambda Functions in the Account
          values = ["arn:${data.aws_partition.current.partition}:lambda"]
        }
      ]
    }
  ]

  # Enable insights for API call rate and API error rate
  insight_selectors = ["ApiCallRateInsight", "ApiErrorRateInsight"]
  tags              = local.tags
}
