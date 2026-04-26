# Outputs del módulo S3

output "bucket_name" {
  description = "Nombre del bucket S3 creado"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3 creado"
  value       = aws_s3_bucket.this.arn
}

output "kms_key_arn" {
  description = "ARN de la clave KMS (CMK) usada para encriptar el bucket"
  value       = aws_kms_key.s3.arn
}
