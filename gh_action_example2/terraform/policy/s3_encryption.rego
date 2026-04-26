# =============================================================
# Policy: s3_encryption.rego
# Valida que todos los buckets S3 tengan encriptación habilitada
# con clave KMS administrada por el cliente (CMK / aws:kms)
# =============================================================
package main

import future.keywords.in

# Obtiene todos los recursos S3 que van a ser creados o actualizados
s3_buckets[resource] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  resource.change.actions[_] in ["create", "update"]
}

# Obtiene las configuraciones de encriptación del plan
s3_encryption_configs[resource] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_server_side_encryption_configuration"
  resource.change.actions[_] in ["create", "update"]
}

# Extrae los bucket IDs que tienen encriptación aws:kms configurada
encrypted_bucket_ids[bucket_id] {
  enc := s3_encryption_configs[_]
  rule := enc.change.after.rule[_]
  rule.apply_server_side_encryption_by_default[_].sse_algorithm == "aws:kms"
  bucket_id := enc.change.after.bucket
}

# Deniega buckets S3 que no tienen configuración de encriptación aws:kms
deny[msg] {
  bucket := s3_buckets[_]
  bucket_name := bucket.change.after.bucket
  not encrypted_bucket_ids[bucket_name]

  msg := sprintf(
    "❌ [S3-ENCRYPTION] El bucket S3 '%s' no tiene encriptación con CMK (aws:kms) configurada. Se requiere 'aws_s3_bucket_server_side_encryption_configuration' con sse_algorithm = 'aws:kms'.",
    [bucket.address]
  )
}

# Deniega si la encriptación existe pero no usa CMK (ej: AES256 sin KMS)
deny[msg] {
  enc := s3_encryption_configs[_]
  rule := enc.change.after.rule[_]
  algo := rule.apply_server_side_encryption_by_default[_].sse_algorithm
  algo != "aws:kms"

  msg := sprintf(
    "❌ [S3-ENCRYPTION] La configuración de encriptación '%s' usa el algoritmo '%s'. Se requiere 'aws:kms' con clave CMK.",
    [enc.address, algo]
  )
}
