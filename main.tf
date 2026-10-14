
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Change this to a globally unique bucket name
variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
  default     = "aropu-reddy-portfolio-2026-demo"
}

# S3 bucket
resource "aws_s3_bucket" "portfolio" {
  bucket = var.bucket_name

  tags = {
    Name        = "Aropu Portfolio Website"
    Environment = "Demo"
  }
}

# Configure S3 static website hosting
resource "aws_s3_bucket_website_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Allow public access settings to be managed by this configuration
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Public read access for website objects
resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicReadForWebsite"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.portfolio.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.portfolio
  ]
}

# Content types for uploaded files
locals {
  mime_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    png  = "image/png"
    svg  = "image/svg+xml"
    webp = "image/webp"
    ico  = "image/x-icon"
    json = "application/json"
    pdf  = "application/pdf"
  }

  website_files = fileset("${path.module}/website", "**")
}

# Upload every file, including files inside assets/
resource "aws_s3_object" "website_files" {
  for_each = local.website_files

  bucket = aws_s3_bucket.portfolio.id
  key    = each.value
  source = "${path.module}/website/${each.value}"

  etag = filemd5("${path.module}/website/${each.value}")

  content_type = lookup(
    local.mime_types,
    try(lower(element(reverse(split(".", each.value)), 0)), ""),
    "application/octet-stream"
  )

  depends_on = [
    aws_s3_bucket_policy.portfolio
  ]
}

# Website URL
output "website_url" {
  description = "S3 static website endpoint"
  value       = "http://${aws_s3_bucket_website_configuration.portfolio.website_endpoint}"
}

output "bucket_name" {
  description = "Created S3 bucket"
  value       = aws_s3_bucket.portfolio.bucket
}