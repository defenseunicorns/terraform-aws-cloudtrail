variable "region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "name_prefix" {
  description = "The name of the CloudTrail"
  type        = string
  default     = "ci-"
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
