#Este archivo sera usado para utilizar los diferentes archivos.sql que se hagan a lo largo del paso de datos desde el dump a la nueva db
#!/usr/bin/env bash
set -euo pipefail

# Cargar .env si existe
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

DB_CONTAINER=urbango_db
DB_NAME=${POSTGRES_DB:-urbango}
DB_USER=${POSTGRES_USER:-urbanuser}

echo ">> Verificando que el contenedor $DB_CONTAINER esté corriendo..."
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
  echo "ERROR: El contenedor ${DB_CONTAINER} no está corriendo."
  echo "  Levántalo primero con: docker compose up -d db"
  exit 1
fi

echo ">> Copiando scripts de migrar_datos al contenedor..."
for sql in migrar_datos/*.sql; do
  base="$(basename "$sql")"
  echo "   - $base"
  docker cp "$sql" "$DB_CONTAINER:/tmp/$base"
done

echo ">> Ejecutando scripts de migrar_datos dentro de la BD $DB_NAME..."
for sql in migrar_datos/*.sql; do
  base="$(basename "$sql")"
  echo ">> Ejecutando $base ..."
  docker exec -i "$DB_CONTAINER" bash -c \
    "psql -U \"$DB_USER\" -d \"$DB_NAME\" -v ON_ERROR_STOP=1 -f \"/tmp/$base\""
done

echo ">> Migración de datos completada."
