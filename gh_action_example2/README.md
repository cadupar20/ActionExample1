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
gh_action_example2/
├── Dockerfile                        # Imagen Docker de demo
├── README.md                         # Este archivo
└── terraform/
    ├── main.tf                       # Raíz: invoca el módulo S3
    ├── variables.tf                  # Variables de entrada
    ├── outputs.tf                    # Outputs del módulo raíz
    ├── envs/
    │   ├── dev.tfvars                # Variables para entorno dev
    │   ├── dev-test.tfvars           # Variables para entorno dev-test
    │   ├── test.tfvars               # Variables para entorno test
    │   └── prod.tfvars               # Variables para entorno prod (main)
    └── modules/
        └── s3/
            ├── main.tf               # Recurso aws_s3_bucket + bloqueo público
            ├── variables.tf
            └── outputs.tf
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

Ejecuta `terraform init → plan → apply` con manejo de errores por paso.
El `apply` solo corre en eventos `push` (no en `pull_request`).

| Step | ID | Descripción |
|---|---|---|
| Checkout | — | Clona el repo en el runner |
| Setup Terraform | — | Instala CLI v1.7.0 |
| Set environment tfvars | `set_env` | Detecta la rama y asigna el `.tfvars` correcto |
| Terraform Init | `tf_init` | Inicializa backend y providers |
| Handle Init failure | — | `if: steps.tf_init.outcome == 'failure'` → echo error + exit 1 |
| Terraform Plan | `tf_plan` | Genera el plan con el `.tfvars` del entorno |
| Handle Plan failure | — | `if: steps.tf_plan.outcome == 'failure'` → echo error + exit 1 |
| Terraform Apply | `tf_apply` | Aplica el plan (solo en `push`) |
| Handle Apply failure | — | `if: steps.tf_apply.outcome == 'failure'` → echo error + exit 1 |
| Apply success | — | Confirma éxito con echo |

```yaml
terraform-build:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: gh_action_example2/terraform
  steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: "1.7.0"

    - name: Set environment tfvars
      id: set_env
      run: |
        BRANCH="${{ github.ref_name }}"
        case "$BRANCH" in
          dev)      TFVARS="envs/dev.tfvars" ;;
          dev-test) TFVARS="envs/dev-test.tfvars" ;;
          test)     TFVARS="envs/test.tfvars" ;;
          main)     TFVARS="envs/prod.tfvars" ;;
          *)        TFVARS="envs/dev.tfvars" ;;
        esac
        echo "TFVARS_FILE=$TFVARS" >> $GITHUB_ENV

    - name: Terraform Init
      id: tf_init
      run: terraform init
      continue-on-error: true

    - name: Handle Init failure
      if: steps.tf_init.outcome == 'failure'
      run: |
        echo "::error::❌ TERRAFORM INIT ha fallado."
        exit 1
    # ... (plan y apply siguen el mismo patrón)
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
│  │  rama → tfvars:                                              │  │
│  │  dev → dev.tfvars │ dev-test → dev-test.tfvars              │  │
│  │  test → test.tfvars │ main → prod.tfvars                    │  │
│  │                                                              │  │
│  │  [checkout] → [setup terraform] → [set env tfvars]          │  │
│  │       │                                                      │  │
│  │       ▼                                                      │  │
│  │  [tf init] ──✗──► [handle init failure] → exit 1            │  │
│  │       │ ✓                                                    │  │
│  │       ▼                                                      │  │
│  │  [tf plan] ──✗──► [handle plan failure] → exit 1            │  │
│  │       │ ✓                                                    │  │
│  │       ▼  (solo en push)                                      │  │
│  │  [tf apply] ──✗──► [handle apply failure] → exit 1          │  │
│  │       │ ✓                                                    │  │
│  │       ▼                                                      │  │
│  │  [✅ apply success]                                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ terraform apply (solo push)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS (por entorno)                           │
│                                                                     │
│   dev          dev-test        test            prod (main)          │
│   ┌─────────┐  ┌─────────┐    ┌─────────┐    ┌─────────┐          │
│   │S3 Bucket│  │S3 Bucket│    │S3 Bucket│    │S3 Bucket│          │
│   │  -dev   │  │-dev-test│    │  -test  │    │  -prod  │          │
│   └─────────┘  └─────────┘    └─────────┘    └─────────┘          │
│   (módulo terraform/modules/s3 — acceso público bloqueado)          │
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
- Módulo Terraform reutilizable para AWS S3
- Terraform apply solo en `push`, no en `pull_request`
