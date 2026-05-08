# =============================================================
# Módulo: S3
# Crea un bucket S3 privado con etiquetas de entorno
# =============================================================

# Clave KMS administrada por el cliente (CMK) para encriptar el bucket
resource "aws_kms_key" "s3" {
  description             = "CMK para encriptar el bucket S3 ${var.bucket_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.bucket_name}-kms-key"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.bucket_name}-key"
  target_key_id = aws_kms_key.s3.key_id
}

# Clave KMS administrada por el cliente (CMK) para encriptar el bucket de logs
resource "aws_kms_key" "logs" {
  description             = "CMK para encriptar el bucket de logs ${var.bucket_name}-access-logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.bucket_name}-logs-kms-key"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.bucket_name}-logs-key"
  target_key_id = aws_kms_key.logs.key_id
}

# Bucket destino para access logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-access-logs"

  tags = {
    Name        = "${var.bucket_name}-access-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encriptación con CMK para el bucket de logs
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.logs.arn
    }
    bucket_key_enabled = true
  }
}

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

# Habilita access logging hacia el bucket de logs
resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "logs/"
}

# Encriptación con clave KMS administrada por el cliente (CMK)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
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
