# Outputs expuestos por el módulo raíz

output "bucket_name" {
  description = "Nombre del bucket S3 creado"
  value       = module.s3_bucket.bucket_name
}

output "bucket_arn" {
  description = "ARN del bucket S3 creado"
  value       = module.s3_bucket.bucket_arn
}
