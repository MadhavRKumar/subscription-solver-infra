output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend-distribution.domain_name
}
