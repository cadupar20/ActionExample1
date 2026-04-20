# gh_action_example2 — Ejemplo de Workflow CI con GitHub Actions

Este directorio forma parte de un repositorio de demostración. Su propósito es ilustrar cómo funciona un workflow de **Integración Continua (CI)** usando GitHub Actions, con dos jobs independientes que corren en paralelo.

---

## Workflow: CI (`gh_action1.yml`)

Ubicación: `.github/workflows/gh_action1.yml`

### Disparadores (`on`)

El workflow se activa en los siguientes eventos:

| Evento | Rama | Condición de ruta |
|---|---|---|
| `push` | `dev` | Solo si hay cambios en `gh_action_example2/**` |
| `pull_request` | `dev` | Solo si hay cambios en `gh_action_example2/**` |
| `workflow_dispatch` | cualquiera | Ejecución manual desde la pestaña Actions |

> El filtro de rutas (`paths`) evita que el workflow se dispare innecesariamente cuando los cambios no afectan a este directorio.

---

### Jobs

El workflow define **dos jobs** que corren en paralelo sobre `ubuntu-latest`.

---

#### Job 1 — `echos` (1st job)

Demuestra la ejecución de comandos de shell básicos dentro de un runner.

| Step | Nombre | Descripción |
|---|---|---|
| 1 | `Run a one-line script` | Ejecuta `echo Hello, world!` |
| 2 | `Run a multi-line script` | Ejecuta múltiples comandos `echo` en secuencia |

```yaml
jobs:
  echos:
    runs-on: ubuntu-latest
    name: 1st job
    steps:
      - name: Run a one-line script
        run: echo Hello, world!

      - name: Run a multi-line script
        run: |
          echo Add other actions to build,
          echo test, and deploy your project.
```

> Nota: el step `actions/checkout@v4` está comentado. Descoméntalo si el job necesita acceder al código del repositorio.

---

#### Job 2 — `variables_entorno` (2nd job)

Demuestra el uso de **variables de entorno** definidas a nivel de step con la clave `env`.

| Variable | Valor |
|---|---|
| `VAR1` | `This is` |
| `VAR2` | `A Demo of` |
| `VAR3` | `GitHub Actions` |
| `VAR4` | `Workflow jobs` |
| `VAR5` | `by Ariel` |

El step imprime todas las variables concatenadas:

```
This is A Demo of GitHub Actions Workflow jobs by Ariel.
```

```yaml
  variables_entorno:
    name: 2nd job
    runs-on: ubuntu-latest
    steps:
      - name: Show the demo running
        env:
          VAR1: This is
          VAR2: A Demo of
          VAR3: GitHub Actions
          VAR4: Workflow jobs
          VAR5: by Ariel
        run: |
          echo $VAR1 $VAR2 $VAR3 $VAR4 $VAR5.
```

---

## Diagrama del flujo

```
push / pull_request → rama: dev, paths: gh_action_example2/**
         │
         ▼
   ┌─────────────────────────────────────┐
   │           Workflow: CI              │
   │                                     │
   │  ┌──────────────┐  ┌─────────────┐ │
   │  │  Job: echos  │  │  Job: vars  │ │
   │  │  (1st job)   │  │  (2nd job)  │ │
   │  │              │  │             │ │
   │  │ • echo hello │  │ • env vars  │ │
   │  │ • echo multi │  │ • echo $VAR │ │
   │  └──────────────┘  └─────────────┘ │
   │       (corren en paralelo)          │
   └─────────────────────────────────────┘
```

---

## Cómo probarlo

1. Asegúrate de estar en la rama `dev` (o crea una rama a partir de ella).
2. Realiza cualquier cambio dentro de `gh_action_example2/` y haz push:

```bash
git checkout dev
# edita algún archivo dentro de gh_action_example2/
git add gh_action_example2/
git commit -m "test: trigger CI workflow"
git push origin dev
```

3. Ve a la pestaña **Actions** de tu repositorio en GitHub para ver la ejecución en tiempo real.

También puedes dispararlo manualmente desde **Actions → CI → Run workflow**.

---

## Conceptos clave demostrados

- Filtrado de eventos por rama y ruta (`branches`, `paths`)
- Ejecución manual con `workflow_dispatch`
- Jobs paralelos en un mismo workflow
- Steps con comandos de una línea y multilínea (`run: |`)
- Variables de entorno a nivel de step (`env`)
