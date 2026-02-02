variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}