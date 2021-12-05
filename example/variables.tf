variable "tags" {
  description = "A map of tags to add to all resources"

  default = {
    "tr:resource-owner"               = "EnterpriseCloudOperations@thomsonreuters.com"
    "tr:application-asset-insight-id" = "206256"
    "tr:environment-type"             = "sandbox"
    "tr:financial-identifier"         = "0000066497"
    "tr:testing"                      = "true"
  }
}

variable "region" {
  description = "AWS region"
}

variable "role_arn" {
  description = "The ARN of the service-linked role that the ASG will use to call other AWS services."
}

variable "subnets" {
  description = "A list of subnet IDs to attach to the ELB"
  type        = list(string)
  default = [
    "subnet-0db6ebf255539095d",
    "subnet-01b2ae39dd6d37863",
    "subnet-0e20b7d2c00110cb6",

  ]
}