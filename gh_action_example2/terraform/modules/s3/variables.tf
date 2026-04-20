# Variables de entrada del módulo S3

variable "bucket_name" {
  description = "Nombre del bucket S3 a crear"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, dev-test, test, prod)"
  type        = string
}
