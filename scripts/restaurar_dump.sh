#!/usr/bin/env bash
set -euo pipefail

# 1) Cargar variables del .env (si existe)
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

# 2) Configuración básica
DB_CONTAINER=urbango_db
DB_NAME=${POSTGRES_DB:-urbango}
DB_USER=${POSTGRES_USER:-urbanuser}
DUMP_FILE=urbango.dump

echo ">> Verificando que el contenedor $DB_CONTAINER esté corriendo..."
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
  echo "ERROR: El contenedor ${DB_CONTAINER} no está corriendo."
  echo "  Levántalo primero con: docker compose up -d db"
  exit 1
fi

echo ">> Asegurando que pg_restore esté instalado en el contenedor..."
docker exec -it "$DB_CONTAINER" bash -c '
  if ! command -v pg_restore >/dev/null 2>&1; then
    apt-get update && apt-get install -y postgresql-client
  fi
'

echo ">> Copiando dump (formato custom) al contenedor..."
docker cp "$DUMP_FILE" "$DB_CONTAINER":/tmp/urbango.dump

echo ">> Restaurando dump (custom) en BD ${DB_NAME}..."
docker exec -it "$DB_CONTAINER" bash -c '
  pg_restore \
    -U '"$DB_USER"' \
    -d '"$DB_NAME"' \
    /tmp/urbango.dump
'

echo ">> Listo: dump restaurado en la BD ${DB_NAME} (tablas en public.*)."
echo "   Revisa con: \\dt public.*"

