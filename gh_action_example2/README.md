# gh_action_example2 — Workflow CI con GitHub Actions + Terraform + Docker

Este directorio es un ejemplo completo de CI con GitHub Actions que incluye:
- Jobs de demostración (echo, variables de entorno)
- Despliegue de infraestructura con Terraform (módulo AWS S3)
- Un Dockerfile de ejemplo
- Manejo de errores por step
- Selección dinámica de entorno por rama

---

## Estructura del proyecto

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

---

## Workflow: CI (`gh_action1.yml`)

Ubicación: `.github/workflows/gh_action1.yml`

### Disparadores (`on`)

| Evento | Ramas | Condición de ruta |
|---|---|---|
| `push` | `dev`, `dev-test`, `test`, `main` | Solo si hay cambios en `gh_action_example2/**` |
| `pull_request` | `dev`, `dev-test`, `test`, `main` | Solo si hay cambios en `gh_action_example2/**` |
| `workflow_dispatch` | cualquiera | Ejecución manual desde la pestaña Actions |

> El filtro `paths` evita disparar el workflow cuando los cambios no afectan este directorio.

---

### Mapeo rama → entorno Terraform

| Rama | Archivo de variables |
|---|---|
| `dev` | `envs/dev.tfvars` |
| `dev-test` | `envs/dev-test.tfvars` |
| `test` | `envs/test.tfvars` |
| `main` | `envs/prod.tfvars` |
| cualquier otra | `envs/dev.tfvars` (fallback) |

---

### Jobs

El workflow define 3 jobs. Los jobs 1 y 2 corren en paralelo. El job 3 (Terraform) corre de forma independiente.

---

#### Job 1 — `echos` (1st job)

Demuestra la ejecución de comandos shell básicos.

| Step | Descripción |
|---|---|
| `Run a one-line script` | Ejecuta `echo Hello, world!` |
| `Run a multi-line script` | Ejecuta múltiples `echo` en secuencia |

```yaml
echos:
  runs-on: ubuntu-latest
  steps:
    - name: Run a one-line script
      run: echo Hello, world!
    - name: Run a multi-line script
      run: |
        echo Add other actions to build,
        echo test, and deploy your project.
```

---

#### Job 2 — `variables_entorno` (2nd job)

Demuestra el uso de variables de entorno a nivel de step con `env`.

| Variable | Valor |
|---|---|
| `VAR1` | `This is` |
| `VAR2` | `A Demo of` |
| `VAR3` | `GitHub Actions` |
| `VAR4` | `Workflow jobs` |
| `VAR5` | `by Ariel` |

Salida: `This is A Demo of GitHub Actions Workflow jobs by Ariel.`

```yaml
variables_entorno:
  runs-on: ubuntu-latest
  steps:
    - name: Show the demo running
      env:
        VAR1: This is
        VAR2: A Demo of
        VAR3: GitHub Actions
        VAR4: Workflow jobs
        VAR5: by Ariel
      run: echo $VAR1 $VAR2 $VAR3 $VAR4 $VAR5.
```

---

#### Job 3 — `terraform-build` (3rd job)

Ejecuta el pipeline completo de validación y despliegue: `init → plan → Checkov → Conftest → apply`.
El `apply` solo corre en eventos `push` a `main` (no en `pull_request`).
Checkov y Conftest solo corren en `pull_request`.

##### Flujo de ejecución

```
[checkout] → [install conftest] → [setup terraform] → [set env tfvars]
     │
     ▼
[tf init] ──✗──► [handle init failure] → exit 1
     │ ✓
     ▼
[tf plan] ──✗──► [handle plan failure] → exit 1
     │ ✓
     ▼
[tf show → tfplan.txt / tfplan.json]
     │
     ▼
[Checkov] ──✗──► [handle checkov failure] → exit 1     ← best practices AWS/CIS
     │ ✓
     ▼
[Conftest] ──✗──► [handle conftest failure] → exit 1   ← políticas custom Rego
     │ ✓
     ▼
[Post plan PR comment] + [Upload artifacts]
     │
     ▼  (solo push a main)
[tf apply] ──✗──► [handle apply failure] → exit 1
     │ ✓
     ▼
[✅ apply success]
```

##### Tabla de steps

| Step | ID | Evento | Descripción |
|---|---|---|---|
| Checkout | — | siempre | Clona el repo en el runner |
| Install conftest | — | siempre | Descarga e instala conftest en `/usr/local/bin` |
| Setup Terraform | — | siempre | Instala CLI v1.7.0 con `terraform_wrapper: false` |
| Set environment tfvars | `set_env` | siempre | Detecta la rama y asigna el `.tfvars` correcto vía `$GITHUB_ENV` |
| Terraform Init | `tf_init` | siempre | Inicializa backend y providers |
| Handle Init failure | — | siempre | `outcome == 'failure'` → echo error + exit 1 |
| Terraform Plan | `tf_plan` | `pull_request` | Genera el plan con `-out=tfplan.bin -no-color -lock=false -parallelism=50` |
| Handle Plan failure | — | siempre | `outcome == 'failure'` → echo error + exit 1 |
| Convert plan to text | `convert_tfplan_text` | `pull_request` | `terraform show -no-color tfplan.bin > tfplan.txt` |
| Convert plan to JSON | `convert_tfplan` | `pull_request` | `terraform show -json tfplan.bin > tfplan.json` |
| **Checkov** | `checkov` | `pull_request` | Análisis estático de best practices sobre archivos `.tf` |
| Handle Checkov failure | — | siempre | `outcome == 'failure'` → echo error + exit 1 |
| Upload Checkov report | — | `pull_request` ✓ | Sube `checkov-report.xml` como artefacto (15 días) |
| **Conftest** | `conftest` | `pull_request` + checkov ✓ | Valida `tfplan.json` contra políticas Rego en `policy/` |
| Handle Conftest failure | — | siempre | `outcome == 'failure'` → echo error + exit 1 |
| Post Plan to PR | — | `pull_request` + conftest ✓ | Publica el plan como comentario en el PR |
| Upload Plan Artifact | — | conftest ✓ | Sube `tfplan.bin` + `tfplan.json` como artefacto (15 días) |
| Terraform Apply | `tf_apply` | `push` a `main` + conftest ✓ | Aplica el plan con `-auto-approve` |
| Handle Apply failure | — | siempre | `outcome == 'failure'` → echo error + exit 1 |
| Apply success | — | `push` | Confirma éxito con echo |

##### Checkov — análisis estático de best practices

[Checkov](https://www.checkov.io/) escanea los archivos `.tf` directamente (sin necesitar el plan) y detecta configuraciones que no siguen las mejores prácticas de seguridad de AWS (CIS Benchmark, NIST, etc.).

Se ejecuta **antes de Conftest** para detectar problemas en el código fuente tempranamente.

```yaml
- name: Install and run Checkov
  if: github.event_name == 'pull_request'
  id: checkov
  run: |
    pip install checkov --quiet
    checkov \
      --directory ${{ env.WORKING_DIR }} \
      --framework terraform \
      --output cli \
      --output junitxml \
      --output-file-path console,checkov-report.xml \
      --no-guide \
      --compact \
      --soft-fail
  continue-on-error: true
```

Ejemplos de checks que realiza Checkov sobre los recursos de este módulo:

| Check | Recurso | Descripción |
|---|---|---|
| `CKV_AWS_19` | `aws_s3_bucket` | Encriptación habilitada |
| `CKV_AWS_21` | `aws_s3_bucket` | Versionado habilitado |
| `CKV_AWS_145` | `aws_s3_bucket` | Encriptación con KMS |
| `CKV_AWS_18` | `aws_s3_bucket` | Access logging habilitado |
| `CKV2_AWS_6` | `aws_s3_bucket` | Public access block configurado |
| `CKV2_AWS_61` | `aws_s3_bucket` | Lifecycle policy configurada |
| `CKV_AWS_7` | `aws_kms_key` | Rotación de clave habilitada |

##### Conftest — validación de políticas custom (Rego/OPA)

[Conftest](https://www.conftest.dev/) evalúa el plan de Terraform en formato JSON contra las políticas escritas en Rego ubicadas en `terraform/policy/`.

Solo corre si Checkov fue exitoso (`if: steps.checkov.outcome == 'success'`).

```yaml
- name: Conftest test
  if: github.event_name == 'pull_request' && steps.checkov.outcome == 'success'
  id: conftest
  working-directory: ${{ env.WORKING_DIR }}
  run: conftest test --no-color tfplan.json
  continue-on-error: true
```

Políticas activas en `terraform/policy/`:

| Archivo | Qué valida |
|---|---|
| `tags.rego` | Tags obligatorios: `App`, `Owner`, `Environment`, `Costcenter`, `Responsable`, `referente`, `backup` |
| `s3_encryption.rego` | Buckets S3 con encriptación `aws:kms` (CMK) |
| `s3_public_access.rego` | Buckets S3 con todas las opciones de bloqueo público en `true` |
| `exceptions.rego` | Tipos de recursos exentos de validación de tags |

Ver documentación detallada en [`terraform/policy/README.md`](terraform/policy/README.md).

##### Diferencia entre Checkov y Conftest

| | Checkov | Conftest |
|---|---|---|
| Qué analiza | Código fuente `.tf` | Plan de Terraform en JSON |
| Políticas | Built-in (CIS, NIST, etc.) | Custom en Rego (OPA) |
| Cuándo falla | Best practices generales de AWS | Reglas específicas del equipo/proyecto |
| Configuración | Sin archivos adicionales | Requiere carpeta `policy/*.rego` |

```yaml
terraform-build:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: gh_action_example2/terraform
  steps:
    - uses: actions/checkout@v4

    - name: Install conftest
      run: |
        wget -O - 'https://github.com/open-policy-agent/conftest/releases/download/v0.68.2/conftest_0.68.2_Linux_x86_64.tar.gz' | tar zxvf - -C /tmp
        sudo mv /tmp/conftest /usr/local/bin/conftest

    - uses: hashicorp/setup-terraform@v3
      with:
        terraform_wrapper: false
        terraform_version: "1.7.0"

    # ... init → plan → show → checkov → conftest → apply
```

##### Diagrama de flujo del Job 3

```
[checkout] → [install conftest] → [setup terraform] → [set env tfvars]
       │
       ▼
[tf init] ──✗──► [handle init failure] → exit 1
       │ ✓
       ▼  (pull_request)
[tf plan -var-file=<env>.tfvars -out=tfplan.bin]
       ──✗──► [handle plan failure] → exit 1
       │ ✓
       ▼  (pull_request)
[tf show → tfplan.txt]  +  [tf show -json → tfplan.json]
       │
       ▼  (pull_request)
┌─────────────────────────────────────────────────┐
│  CHECKOV  — análisis estático sobre archivos .tf │
│  CKV_AWS_19  encriptación habilitada             │
│  CKV_AWS_145 encriptación con KMS                │
│  CKV_AWS_18  access logging habilitado           │
│  CKV2_AWS_6  public access block configurado     │
│  CKV_AWS_7   rotación de clave KMS               │
└──────────────┬──────────────────────────────────┘
       ──✗──► [handle checkov failure] → exit 1
       │ ✓
       ▼  (pull_request + checkov ✓)
┌─────────────────────────────────────────────────┐
│  CONFTEST  — políticas Rego sobre tfplan.json    │
│  tags.rego          → App, Owner, Environment,  │
│                        Costcenter, Responsable,  │
│                        referente, backup         │
│  s3_encryption.rego → aws:kms con CMK           │
│  s3_public_access.rego → bloqueo público total  │
└──────────────┬──────────────────────────────────┘
       ──✗──► [handle conftest failure] → exit 1
       │ ✓
       ▼
[Post PR comment con tfplan.txt]
[Upload artifacts: tfplan.bin + tfplan.json + checkov-report.xml]
       │
       ▼  (push a main + conftest ✓)
[tf apply -auto-approve tfplan.bin]
       ──✗──► [handle apply failure] → exit 1
       │ ✓
       ▼
[✅ apply success]
```

---

## Arquitectura del sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                            │
│                                                                     │
│   Ramas: dev ──► dev-test ──► test ──► main                        │
│                                                                     │
│   Push / Pull Request con cambios en gh_action_example2/**          │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ dispara
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    GitHub Actions — Workflow CI                      │
│                                                                     │
│  ┌─────────────────┐  ┌──────────────────────┐                     │
│  │   Job 1: echos  │  │ Job 2: variables_env  │  (paralelo)        │
│  │                 │  │                       │                     │
│  │ • echo hello    │  │ • env VAR1..VAR5      │                     │
│  │ • echo multi    │  │ • echo $VAR1..$VAR5   │                     │
│  └─────────────────┘  └──────────────────────┘                     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              Job 3: terraform-build                          │  │
│  │                                                              │  │
│  │  [checkout] → [install conftest] → [setup terraform]        │  │
│  │       → [set env tfvars]                                     │  │
│  │       │                                                      │  │
│  │       ▼                                                      │  │
│  │  [tf init] ──✗──► [handle init failure] → exit 1            │  │
│  │       │ ✓                                                    │  │
│  │       ▼  (pull_request)                                      │  │
│  │  [tf plan] ──✗──► [handle plan failure] → exit 1            │  │
│  │       │ ✓                                                    │  │
│  │       ▼  (pull_request)                                      │  │
│  │  [tf show → tfplan.txt + tfplan.json]                        │  │
│  │       │                                                      │  │
│  │       ▼  (pull_request)                                      │  │
│  │  [Checkov] ──✗──► [handle checkov failure] → exit 1         │  │
│  │   best practices AWS/CIS sobre archivos .tf                  │  │
│  │       │ ✓                                                    │  │
│  │       ▼  (pull_request + checkov ✓)                          │  │
│  │  [Conftest] ──✗──► [handle conftest failure] → exit 1       │  │
│  │   políticas Rego: tags, s3_encryption, s3_public_access      │  │
│  │       │ ✓                                                    │  │
│  │       ▼                                                      │  │
│  │  [Post PR comment] + [Upload artifacts]                      │  │
│  │       │                                                      │  │
│  │       ▼  (push a main + conftest ✓)                          │  │
│  │  [tf apply] ──✗──► [handle apply failure] → exit 1          │  │
│  │       │ ✓                                                    │  │
│  │       ▼                                                      │  │
│  │  [✅ apply success]                                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ terraform apply (solo push a main)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS (por entorno)                           │
│                                                                     │
│   dev          dev-test        test            prod (main)          │
│   ┌─────────┐  ┌─────────┐    ┌─────────┐    ┌─────────┐          │
│   │S3 Bucket│  │S3 Bucket│    │S3 Bucket│    │S3 Bucket│          │
│   │  -dev   │  │-dev-test│    │  -test  │    │  -prod  │          │
│   └─────────┘  └─────────┘    └─────────┘    └─────────┘          │
│   KMS CMK + access logging + public access block                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Cómo deshabilitar un job sin borrarlo

La forma más limpia es agregar `if: false` directamente en el job:

```yaml
terraform-build:
  name: 3rd job - Terraform Build
  if: false   # ← deshabilitado temporalmente, GitHub lo saltea
  runs-on: ubuntu-latest
```

Para volver a habilitarlo, eliminá esa línea o cambiá a `if: true`.

### Otras condiciones útiles con `if`

| Condición | Comportamiento |
|---|---|
| `if: false` | Siempre deshabilitado |
| `if: true` | Siempre habilitado (comportamiento por defecto) |
| `if: github.event_name == 'push'` | Solo corre en push (no en pull_request) |
| `if: github.event_name == 'workflow_dispatch'` | Solo corre si se dispara manualmente |
| `if: github.ref_name == 'main'` | Solo corre en la rama main |
| `if: github.ref_name != 'main'` | Corre en todas las ramas excepto main |
| `if: needs.otro_job.result == 'success'` | Solo si un job previo fue exitoso |

### Ejemplo: deshabilitar apply en pull_request

```yaml
- name: Terraform Apply
  if: github.event_name == 'push'   # no aplica en PRs, solo en push
  run: terraform apply -auto-approve tfplan
```

### Ejemplo: job que solo corre en prod

```yaml
terraform-build:
  if: github.ref_name == 'main'   # solo se ejecuta al mergear a main
  runs-on: ubuntu-latest
```

---

## Dockerfile de demo

El `Dockerfile` incluido es un ejemplo básico alineado con el workflow:

```dockerfile
FROM node:20-alpine          # imagen base liviana
WORKDIR /app                 # directorio de trabajo
COPY . .                     # copia archivos del proyecto
ENV APP_ENV=demo             # variable de entorno (similar al job 2)
CMD ["sh", "-c", "echo Hello from Docker! Running in $APP_ENV mode."]
```

Para probarlo localmente:

```bash
cd gh_action_example2
docker build -t gh-action-demo .
docker run --rm gh-action-demo
# Salida: Hello from Docker! Running in demo mode.
```

---

## Cómo probarlo

```bash
git checkout dev
# realizá cambios dentro de gh_action_example2/
git add gh_action_example2/
git commit -m "test: trigger CI workflow"
git push origin dev
```

Luego ve a Actions → CI en tu repositorio para ver la ejecución en tiempo real.
También podés dispararlo manualmente desde Actions → CI → Run workflow.

---

## Conceptos clave demostrados

- Filtrado de eventos por rama y ruta (`branches`, `paths`)
- Ejecución manual con `workflow_dispatch`
- Jobs paralelos en un mismo workflow
- Variables de entorno a nivel de step (`env`) y a nivel de workflow (`$GITHUB_ENV`)
- Selección dinámica de `.tfvars` según rama con `case`
- Manejo de errores por step con `continue-on-error` + `if: steps.<id>.outcome`
- Mensajes de error en GitHub CI con `echo "::error::mensaje"`
- Deshabilitar jobs con `if: false` sin eliminarlos
- Módulo Terraform reutilizable para AWS S3 con KMS, logging y bloqueo público
- Terraform apply solo en `push` a `main`, no en `pull_request`
- Análisis estático de infraestructura con **Checkov** (CIS Benchmark / best practices AWS)
- Validación de políticas custom con **Conftest/OPA** (tags, encriptación, acceso público)
- Pipeline de validación en cadena: Checkov debe pasar antes de ejecutar Conftest
- Publicación del plan de Terraform como comentario en el Pull Request
- Subida de artefactos (plan binario, JSON, reporte Checkov) con retención configurable
