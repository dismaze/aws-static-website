provider "aws" {
  region = var.aws_region
}

# 1. S3 Bucket for State
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  
  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }
}

# 2. Enable Versioning (Crucial for State recovery)
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. DynamoDB Table for Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}