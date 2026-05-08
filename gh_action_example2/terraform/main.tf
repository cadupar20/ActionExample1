# =============================================================
# EJEMPLO PARA LA EJECUCIÓN DEL WORKFLOW gh_action1.yml
# Archivo principal de Terraform — raíz del proyecto
# =============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configura el provider de AWS — la región se recibe desde el .tfvars del entorno
provider "aws" {
  region = var.aws_region
}

# Invoca el módulo de S3 definido en ./modules/s3
module "s3_bucket" {
  source = "./modules/s3"

  # Nombre del bucket — se recibe desde el .tfvars del entorno
  bucket_name = var.bucket_name

  # Etiquetas comunes para todos los recursos del entorno
  environment = var.environment
}
