# Repositorio de Ejemplos — GitHub Actions

Repositorio de demostración con ejemplos prácticos de GitHub Actions, Terraform, Docker y validación de infraestructura con Checkov y Conftest/OPA.

## Estructura del repositorio

```
.
├── .github/
│   └── workflows/
│       ├── gh_action1.yml              # Workflow CI básico (Terraform init → plan → apply)
│       └── conftest-ci-sample.yml      # Workflow CI completo con Checkov + Conftest/OPA
├── gh_action_example2/
│   ├── Dockerfile                      # Imagen Docker de demo (Node.js Alpine)
│   ├── README.md                       # Documentación detallada del ejemplo
│   └── terraform/
│       ├── main.tf                     # Módulo raíz que invoca el módulo S3
│       ├── variables.tf                # Variables de entrada del módulo raíz
│       ├── outputs.tf                  # Outputs del módulo raíz
│       ├── envs/
│       │   ├── dev.tfvars              # Variables para entorno dev
│       │   ├── dev-test.tfvars         # Variables para entorno dev-test
│       │   ├── test.tfvars             # Variables para entorno test
│       │   └── prod.tfvars             # Variables para entorno prod (main)
│       ├── modules/
│       │   └── s3/
│       │       ├── main.tf             # Recurso aws_s3_bucket + bloqueo público + KMS
│       │       ├── variables.tf
│       │       └── outputs.tf
│       └── policy/
│           ├── README.md               # Documentación de políticas Rego
│           ├── tags.rego               # Política: tags obligatorios
│           ├── s3_encryption.rego      # Política: encriptación aws:kms
│           ├── s3_public_access.rego   # Política: bloqueo público total
│           └── exceptions.rego         # Política: tipos exentos de validación de tags
└── README.md                           # Este archivo
```

## Ejemplos incluidos

| Carpeta / Workflow | Descripción |
|---|---|
| `.github/workflows/gh_action1.yml` | Workflow CI básico con jobs de demostración (echo, variables de entorno) y pipeline Terraform (init → plan → apply) con selección dinámica de `.tfvars` por rama |
| `.github/workflows/conftest-ci-sample.yml` | Workflow CI completo con Terraform + Checkov (best practices AWS) + Conftest/OPA (políticas Rego custom), publicación del plan como comentario en PR y subida de artefactos |
| `gh_action_example2/` | Ejemplo completo que incluye: Dockerfile demo, módulo Terraform reutilizable para S3 con KMS, 4 entornos (dev, dev-test, test, prod), y políticas Rego para validación de tags, encriptación y acceso público |

## Tecnologías y herramientas

| Herramienta | Propósito |
|---|---|
| **GitHub Actions** | Plataforma de CI/CD para automatizar builds, tests y deploys |
| **Terraform** | Infraestructura como código (IaC) para aprovisionar recursos en AWS |
| **Checkov** | Análisis estático de seguridad sobre archivos `.tf` (CIS Benchmark, best practices AWS) |
| **Conftest / OPA** | Validación de políticas custom escritas en Rego sobre el plan de Terraform JSON |
| **Docker** | Containerización del entorno de demostración |

### Checkov — análisis estático de best practices

Checkov escanea los archivos `.tf` directamente y detecta configuraciones inseguras. Se ejecuta **antes de Conftest** para detectar problemas tempranamente.

Ejemplos de checks incluidos:

| Check | Recurso | Descripción |
|---|---|---|
| `CKV_AWS_19` | `aws_s3_bucket` | Encriptación habilitada |
| `CKV_AWS_21` | `aws_s3_bucket` | Versionado habilitado |
| `CKV_AWS_145` | `aws_s3_bucket` | Encriptación con KMS |
| `CKV_AWS_18` | `aws_s3_bucket` | Access logging habilitado |
| `CKV2_AWS_6` | `aws_s3_bucket` | Public access block configurado |
| `CKV2_AWS_61` | `aws_s3_bucket` | Lifecycle policy configurada |
| `CKV_AWS_7` | `aws_kms_key` | Rotación de clave habilitada |

### Conftest — validación de políticas custom (Rego/OPA)

Conftest evalúa el plan de Terraform en formato JSON contra políticas Rego ubicadas en `terraform/policy/`.

| Archivo | Qué valida |
|---|---|
| `tags.rego` | Tags obligatorios: `App`, `Owner`, `Environment`, `Costcenter`, `Responsable`, `referente`, `backup` |
| `s3_encryption.rego` | Buckets S3 con encriptación `aws:kms` (CMK) |
| `s3_public_access.rego` | Buckets S3 con todas las opciones de bloqueo público en `true` |
| `exceptions.rego` | Tipos de recursos exentos de validación de tags |

## Requisitos

- Cuenta en [GitHub](https://github.com)
- Repositorio con GitHub Actions habilitado (activo por defecto en repos públicos y privados)
- (Opcional) Credenciales AWS configuradas como secrets del repositorio para el job de Terraform

## Uso rápido

1. Clona el repositorio:

```bash
git clone <repo-url>
```

2. Explora los workflows en `.github/workflows/` y adapta los ejemplos a tu proyecto.

3. Haz un push a la rama `dev` o abre un pull request para ver los workflows en acción.

4. (Opcional) Para probar el workflow con Conftest, cambia `if: false` a `if: true` en el job `terraform` de `conftest-ci-sample.yml`.

## Mapeo rama → entorno Terraform

| Rama | Archivo de variables |
|---|---|
| `dev` | `envs/dev.tfvars` |
| `dev-test` | `envs/dev-test.tfvars` |
| `test` | `envs/test.tfvars` |
| `main` | `envs/prod.tfvars` |
| cualquier otra | `envs/dev.tfvars` (fallback) |

## Contribuciones

Las contribuciones son bienvenidas. Abre un *issue* para discutir cambios o envía un *pull request* con mejoras.

## Licencia

Indica la licencia del proyecto aquí (por ejemplo, MIT).