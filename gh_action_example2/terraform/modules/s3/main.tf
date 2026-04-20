# =============================================================
# Módulo: S3
# Crea un bucket S3 privado con etiquetas de entorno
# =============================================================

# Recurso principal: bucket S3
resource "aws_s3_bucket" "this" {
  # Nombre del bucket — debe ser único globalmente en AWS
  bucket = var.bucket_name

  # Etiquetas para identificar el recurso por entorno
  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Bloquea todo acceso público al bucket (buena práctica de seguridad)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
