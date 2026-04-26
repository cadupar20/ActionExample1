# =============================================================
# Policy: tags.rego
# Valida que todos los recursos del plan tengan los tags
# obligatorios: App, Owner, Environment, Costcenter, Responsable
# =============================================================
package main

import future.keywords.in

# Tags obligatorios para todos los recursos
required_tags := {"App", "Owner", "Environment", "Costcenter", "Responsable"}

# Obtiene todos los recursos del plan que van a ser creados o actualizados
# excluyendo tipos que no soportan tags
resource_changes[resource] {
  resource := input.resource_changes[_]
  resource.change.actions[_] in ["create", "update"]
  not tag_exempt_types[resource.type]
  not tag_exceptions[resource.address]
}

# Detecta recursos que no tienen alguno de los tags requeridos
deny[msg] {
  resource := resource_changes[_]
  tags := resource.change.after.tags

  # Verifica cada tag obligatorio
  required_tag := required_tags[_]
  not tags[required_tag]

  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) no tiene el tag obligatorio '%s'.",
    [resource.address, resource.type, required_tag]
  )
}

# Detecta recursos que tienen el tag pero con valor vacío
deny[msg] {
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
deny[msg] {
  resource := resource_changes[_]
  not resource.change.after.tags

  msg := sprintf(
    "❌ [TAGS] El recurso '%s' (tipo: %s) no tiene ningún tag definido.",
    [resource.address, resource.type]
  )
}
