# =============================================================
# EJEMPLO PARA LA EJECUCIÓN DEL WORKFLOW gh_action1.yml
# Este Dockerfile es un ejemplo básico de prueba que demuestra
# el flujo CI dentro de una rama (branch git) definida en el 
# archivo gh_action1.yml.
# =============================================================

# Define la imagen base oficial de Node.js (versión LTS sobre Alpine para menor tamaño)
FROM node:20-alpine

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia todos los archivos del directorio actual al directorio de trabajo del contenedor
COPY . .

# Define una variable de entorno de ejemplo (equivalente al uso de "env" en el workflow)
ENV APP_ENV=demo

# Comando que se ejecuta al iniciar el contenedor
# Imprime un mensaje similar al step "Run a one-line script" del job "echos"
CMD ["sh", "-c", "echo Hello from Docker! Running in $APP_ENV mode."]
