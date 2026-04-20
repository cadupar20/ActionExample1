# Outputs del módulo S3

output "bucket_name" {
  description = "Nombre del bucket S3 creado"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3 creado"
  value       = aws_s3_bucket.this.arn
}
