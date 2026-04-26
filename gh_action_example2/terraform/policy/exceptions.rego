# =============================================================
# Policy: exceptions.rego
# Define recursos o tipos que están exentos de ciertas políticas.
# Agregar aquí solo excepciones justificadas y documentadas.
# =============================================================
package main

# Recursos exentos de la validación de tags (por dirección exacta del recurso)
# Ejemplo: recursos de datos (data sources) o recursos de soporte sin tags propios
tag_exceptions := {
  # "aws_kms_alias.s3",   # los alias de KMS no soportan tags directamente
}

# Tipos de recursos que no soportan tags y deben ignorarse en la validación
tag_exempt_types := {
  "aws_kms_alias",
  "aws_s3_bucket_server_side_encryption_configuration",
  "aws_s3_bucket_public_access_block",
  "aws_s3_bucket_logging",
}
