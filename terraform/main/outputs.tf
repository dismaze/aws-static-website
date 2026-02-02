output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cdn.id
}

output "lambda_function_name" {
  description = "Lambda function name for gallery manifest generation"
  value       = aws_lambda_function.gallery_manifest.function_name
}

output "route53_nameservers" {
  description = "Route 53 nameservers for your domain"
  value       = aws_route53_zone.primary.name_servers
}