terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state-bucket"    # ← Must match terraform/backend/terraform.tfvars, bucket_name
    key            = "terraform/terraform.tfstate"
    region         = "eu-west-3"                    # ← Must match terraform/backend/terraform.tfvars, aws_region
    encrypt        = true
    use_lockfile   = true
  }
}

# Primary provider
provider "aws" {
  region = var.aws_region
}

# Provider for us-east-1 (required for ACM certificates with CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}