variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for website content"
  type        = string
}

variable "gallery_prefix" {
  description = "Prefix/folder for gallery images"
  type        = string
  default     = "img/gallery/"
}