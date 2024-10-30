resource "aws_s3_bucket" "frontend-bucket" {
  bucket_prefix = "subscription-frontend"

  tags = {
    Name = "frontend-bucket"
  }

}

resource "aws_s3_bucket_public_access_block" "frontend-bucket-public-access-block" {
  bucket = aws_s3_bucket.frontend-bucket.bucket
}

resource "aws_s3_bucket_policy" "frontend-bucket-policy" {
  bucket = aws_s3_bucket.frontend-bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "Service" : "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.frontend-bucket.arn}/*"
        ],
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend-distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "frontend-bucket-versioning" {
  bucket = aws_s3_bucket.frontend-bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend-bucket-website" {
  bucket = aws_s3_bucket.frontend-bucket.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_cloudfront_origin_access_control" "frontend-bucket-origin-access-control" {
  name                              = "frontend-bucket-origin-access-control"
  description                       = "Restrict access to the frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "frontend-distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend-bucket-origin-access-control.id
    origin_id                = aws_s3_bucket.frontend-bucket.bucket
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = aws_s3_bucket.frontend-bucket.bucket
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "frontend-distribution"
  }
}

