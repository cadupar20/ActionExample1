# Políticas Conftest / OPA

Políticas escritas en [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) para validar el plan de Terraform antes de aplicarlo.

## Versión de sintaxis Rego

Todos los archivos usan `import rego.v1`, que habilita la sintaxis moderna de OPA (v0.59+):

| Sintaxis antigua (v0) | Sintaxis nueva (v1) |
|---|---|
| `deny[msg] { ... }` | `deny contains msg if { ... }` |
| `resource_changes[r] { ... }` | `resource_changes contains r if { ... }` |
| `import future.keywords.in` | `import rego.v1` (incluye todos los keywords) |

`import rego.v1` reemplaza a `import future.keywords.*` e impone el uso obligatorio de `if` y `contains`, eliminando ambigüedades de la sintaxis anterior.

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
terraform plan -out=tfplan.bin
terraform show -json tfplan.bin > tfplan.json

# Exclusivo en powershell de Windows para crear el Json correctamente
 terraform show -json tfplan | Out-File tfplan.json -Encoding utf8

# Ejecutar conftest contra todas las políticas
conftest test --no-color tfplan.json

# Ejecutar solo una política específica
conftest test --no-color -p policy/tags.rego tfplan.json

# Verificar sintaxis de un archivo rego (requiere opa CLI)
opa check policy/tags.rego

# Verificar sintaxis de un archivo rego (usando conftest CLI)
conftest verify policy/tags.rego

# Verificar sintaxis del path policy\ (usando conftest CLI)
 conftest verify .\policy\
 
0 tests, 0 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

## Resultado del conftest test ejemplo:
```bash
❯ conftest test tfplan.json
FAIL - tfplan.json - main - ❌ [S3-ENCRYPTION] El bucket S3 'module.s3_bucket.aws_s3_bucket.logs' no tiene encriptación con CMK (aws:kms) configurada. Se requiere 'aws_s3_bucket_server_side_encryption_configuration' con sse_algorithm = 'aws:kms'.
FAIL - tfplan.json - main - ❌ [S3-ENCRYPTION] El bucket S3 'module.s3_bucket.aws_s3_bucket.this' no tiene encriptación con CMK (aws:kms) configurada. Se requiere 'aws_s3_bucket_server_side_encryption_configuration' con sse_algorithm = 'aws:kms'.
FAIL - tfplan.json - main - ❌ [S3-PUBLIC-ACCESS] El bucket S3 'module.s3_bucket.aws_s3_bucket.logs' no tiene bloqueado el acceso público. Se requiere 'aws_s3_bucket_public_access_block' con todas las opciones en true (block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets).
FAIL - tfplan.json - main - ❌ [S3-PUBLIC-ACCESS] El bucket S3 'module.s3_bucket.aws_s3_bucket.this' no tiene bloqueado el acceso público. Se requiere 'aws_s3_bucket_public_access_block' con todas las opciones en true (block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets).
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.logs' (tipo: aws_kms_key) no tiene el tag obligatorio 'App'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.logs' (tipo: aws_kms_key) no tiene el tag obligatorio 'Costcenter'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.logs' (tipo: aws_kms_key) no tiene el tag obligatorio 'Owner'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.logs' (tipo: aws_kms_key) no tiene el tag obligatorio 'Responsable'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.s3' (tipo: aws_kms_key) no tiene el tag obligatorio 'App'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.s3' (tipo: aws_kms_key) no tiene el tag obligatorio 'Costcenter'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.s3' (tipo: aws_kms_key) no tiene el tag obligatorio 'Owner'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_kms_key.s3' (tipo: aws_kms_key) no tiene el tag obligatorio 'Responsable'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.logs' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'App'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.logs' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'Costcenter'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.logs' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'Owner'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.logs' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'Responsable'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.this' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'App'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.this' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'Costcenter'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.this' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'Owner'.
FAIL - tfplan.json - main - ❌ [TAGS] El recurso 'module.s3_bucket.aws_s3_bucket.this' (tipo: aws_s3_bucket) no tiene el tag obligatorio 'Responsable'.

20 tests, 0 passed, 0 warnings, 20 failures, 0 exceptions
```


## Agregar excepciones

Editar `exceptions.rego` y agregar el tipo o dirección del recurso en el set correspondiente.
Solo agregar excepciones justificadas con un comentario explicativo.
