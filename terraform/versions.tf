terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # For a real project state would live in S3 with DynamoDB locking,
  # configured per environment. Left local here since this is review-only.
  # backend "s3" {}
}
