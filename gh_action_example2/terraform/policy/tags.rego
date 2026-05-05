# =====================================================================================
# Policy: tags.rego
# Valida que todos los recursos del plan tengan los tags
# obligatorios: app, owner, environment, costcenter, responsable, referente, backup
# =====================================================================================
package main

import rego.v1

# Tags obligatorios para todos los recursos
required_tags := {"app", "owner", "environment", "costcenter", "responsable", "referente", "backup"}

# Valores permitidos para el tag backup
allowed_backup_values := {"backup", "no-backup"}

# Obtiene todos los recursos del plan que van a ser creados o actualizados
# excluyendo tipos que no soportan tags
resource_changes contains resource if {
  resource := input.resource_changes[_]
  resource.change.actions[_] in ["create", "update"]
  not tag_exempt_types[resource.type]
  not tag_exceptions[resource.address]
}

# Detecta recursos que no tienen alguno de los tags requeridos
deny contains msg if {
  resource := resource_changes[_]
  tags := resource.change.after.tags
  required_tag := required_tags[_]
  not tags[required_tag]
  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) no tiene el tag obligatorio '%s'.",
    [resource.address, resource.type, required_tag]
  )
}

# Detecta recursos que tienen el tag pero con valor vacío
deny contains msg if {
  resource := resource_changes[_]
  tags := resource.change.after.tags
  required_tag := required_tags[_]
  tags[required_tag] == ""
  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) tiene el tag '%s' con valor vacío.",
    [resource.address, resource.type, required_tag]
  )
}

# Detecta recursos que no tienen el bloque tags en absoluto
deny contains msg if {
  resource := resource_changes[_]
  not resource.change.after.tags
  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) no tiene ningún tag definido.",
    [resource.address, resource.type]
  )
}

# =============================================================
# Validaciones especificas para nuevos tags
# =============================================================

# Validacion: tag 'referente' no puede ser string vacío
# En Rego v1 no existe || — se usan reglas separadas para cada condición
deny contains msg if {
  resource := resource_changes[_]
  tags := resource.change.after.tags
  tags["referente"] == ""
  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) tiene el tag 'referente' con valor vacío.",
    [resource.address, resource.type]
  )
}

# Validacion: tag 'referente' no puede ser solo espacios en blanco
deny contains msg if {
  resource := resource_changes[_]
  tags := resource.change.after.tags
  regex.match(`^\s+$`, tags["referente"])
  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) tiene el tag 'referente' con solo espacios en blanco.",
    [resource.address, resource.type]
  )
}

# Validacion: tag 'backup' solo admite "backup" o "no-backup"
deny contains msg if {
  resource := resource_changes[_]
  tags := resource.change.after.tags
  not tags["backup"] in allowed_backup_values
  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) tiene valor inválido para tag 'backup': '%s'. Valores admitidos: 'backup', 'no-backup'.",
    [resource.address, resource.type, tags["backup"]]
  )
}
