# Variables de entrada para el módulo raíz

variable "aws_region" {
  description = "Región de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre del bucket S3 a crear"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, dev-test, test, prod)"
  type        = string
}
