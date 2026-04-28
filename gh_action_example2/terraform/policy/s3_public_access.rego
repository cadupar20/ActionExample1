# =============================================================
# Policy: s3_public_access.rego
# Valida que todos los buckets S3 tengan bloqueado el acceso
# público mediante aws_s3_bucket_public_access_block con
# todas las opciones habilitadas
# =============================================================
package main

import rego.v1

# Obtiene todos los recursos S3 que van a ser creados o actualizados
s3_buckets contains resource if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  resource.change.actions[_] in ["create", "update"]
}

# Obtiene todos los recursos de bloqueo de acceso público
s3_public_access_blocks contains resource if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.change.actions[_] in ["create", "update"]
}

# Extrae los bucket IDs que tienen TODAS las opciones de bloqueo en true
fully_blocked_bucket_ids contains bucket_id if {
  block := s3_public_access_blocks[_]
  block.change.after.block_public_acls       == true
  block.change.after.block_public_policy     == true
  block.change.after.ignore_public_acls      == true
  block.change.after.restrict_public_buckets == true
  bucket_id := block.change.after.bucket
}

# Deniega buckets que no tienen el recurso aws_s3_bucket_public_access_block asociado
deny contains msg if {
  bucket := s3_buckets[_]
  bucket_name := bucket.change.after.bucket
  not fully_blocked_bucket_ids[bucket_name]

  msg := sprintf(
    "❌ [S3-PUBLIC-ACCESS] El bucket S3 '%s' no tiene bloqueado el acceso público. Se requiere 'aws_s3_bucket_public_access_block' con todas las opciones en true (block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets).",
    [bucket.address]
  )
}

# Deniega si alguna opción de bloqueo está en false
deny contains msg if {
  block := s3_public_access_blocks[_]
  block.change.after.block_public_acls == false

  msg := sprintf(
    "❌ [S3-PUBLIC-ACCESS] '%s': 'block_public_acls' debe ser true.",
    [block.address]
  )
}

deny contains msg if {
  block := s3_public_access_blocks[_]
  block.change.after.block_public_policy == false

  msg := sprintf(
    "❌ [S3-PUBLIC-ACCESS] '%s': 'block_public_policy' debe ser true.",
    [block.address]
  )
}

deny contains msg if {
  block := s3_public_access_blocks[_]
  block.change.after.ignore_public_acls == false

  msg := sprintf(
    "❌ [S3-PUBLIC-ACCESS] '%s': 'ignore_public_acls' debe ser true.",
    [block.address]
  )
}

deny contains msg if {
  block := s3_public_access_blocks[_]
  block.change.after.restrict_public_buckets == false

  msg := sprintf(
    "❌ [S3-PUBLIC-ACCESS] '%s': 'restrict_public_buckets' debe ser true.",
    [block.address]
  )
}
