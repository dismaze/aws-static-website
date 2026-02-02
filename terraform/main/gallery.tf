# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "gallery-manifest-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda to access S3
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.website.arn}/${var.gallery_prefix}manifest.json"
      }
    ]
  })
}

# IAM Policy for Lambda CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "lambda-logs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "gallery_manifest" {
  filename      = "lambda_function.zip"
  function_name = "gallery-manifest-generator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  timeout       = 30

  environment {
    variables = {
      BUCKET_NAME    = aws_s3_bucket.website.id
      GALLERY_PREFIX = var.gallery_prefix
    }
  }

  depends_on = [aws_iam_role_policy.lambda_s3_policy]
}

# S3 Event Notification - Object Created/Removed
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket     = aws_s3_bucket.website.id
  depends_on = [aws_lambda_permission.allow_s3_created, aws_lambda_permission.allow_s3_deleted]

  lambda_function {
    lambda_function_arn = aws_lambda_function.gallery_manifest.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.gallery_prefix
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.gallery_manifest.arn
    events              = ["s3:ObjectRemoved:*"]
    filter_prefix       = var.gallery_prefix
  }
}

# Lambda Permission - Allow S3 to invoke on ObjectCreated
resource "aws_lambda_permission" "allow_s3_created" {
  statement_id  = "AllowExecutionFromS3Created"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gallery_manifest.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.website.arn
  source_account = data.aws_caller_identity.current.account_id
}

# Lambda Permission - Allow S3 to invoke on ObjectRemoved
resource "aws_lambda_permission" "allow_s3_deleted" {
  statement_id  = "AllowExecutionFromS3Deleted"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gallery_manifest.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.website.arn
  source_account = data.aws_caller_identity.current.account_id
}