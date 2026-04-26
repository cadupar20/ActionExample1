# Políticas Conftest / OPA

Políticas escritas en [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) para validar el plan de Terraform antes de aplicarlo.

## Estructura

```
policy/
├── tags.rego             # Valida tags obligatorios en todos los recursos
├── s3_encryption.rego    # Valida encriptación CMK (aws:kms) en buckets S3
├── s3_public_access.rego # Valida bloqueo de acceso público en buckets S3
├── exceptions.rego       # Tipos y recursos exentos de validaciones
└── README.md
```

## Políticas activas

### tags.rego
Todos los recursos (excepto los listados en `exceptions.rego`) deben tener los siguientes tags:

| Tag | Descripción |
|-----|-------------|
| `App` | Nombre de la aplicación o sistema |
| `Owner` | Equipo o área dueña del recurso |
| `Environment` | Entorno: dev, dev-test, test, prod |
| `Costcenter` | Centro de costos para facturación |
| `Responsable` | Persona responsable del recurso |

### s3_encryption.rego
Los buckets S3 deben tener:
- Recurso `aws_s3_bucket_server_side_encryption_configuration` asociado
- `sse_algorithm = "aws:kms"` (no se acepta AES256 sin CMK)
- `kms_master_key_id` apuntando a una CMK

### s3_public_access.rego
Los buckets S3 deben tener un recurso `aws_s3_bucket_public_access_block` con:
- `block_public_acls = true`
- `block_public_policy = true`
- `ignore_public_acls = true`
- `restrict_public_buckets = true`

## Uso local

```bash
# Generar el plan en JSON
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Ejecutar conftest contra todas las políticas
conftest test --no-color tfplan.json

# Ejecutar solo una política específica
conftest test --no-color -p policy/tags.rego tfplan.json
```

## Agregar excepciones

Editar `exceptions.rego` y agregar el tipo o dirección del recurso en el set correspondiente.
Solo agregar excepciones justificadas con un comentario explicativo.
