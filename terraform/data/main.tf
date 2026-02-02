terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The data source must be outside the terraform block
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "terraform-jvbdev-state"
    key    = "intelligentyoga/terraform.tfstate"
    region = "eu-west-3"
  }
}

# Outputs must also be outside the terraform block
output "bucket_name" {
  value = data.terraform_remote_state.infra.outputs.bucket_name
}

output "cloudfront_id" {
  value = data.terraform_remote_state.infra.outputs.cloudfront_distribution_id
}