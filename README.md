# UrbanGO DB Migrations (PostgreSQL/PostGIS + Flyway) — Data Engineering Pipeline

> **[TODO: Describe el “por qué” del proyecto / contexto del negocio aquí]**

Este repo implementa un pipeline reproducible para **crear**, **versionar** y **poblar** la base de datos de UrbanGO usando **Docker**, **PostgreSQL + PostGIS**, **Flyway** y scripts de migración de datos (ETL “one-shot”). [file:108][file:18][file:16]

---

## Stack
- PostgreSQL + PostGIS (geometrías para POIs y posiciones). [file:108]
- Flyway para migraciones versionadas del esquema (`V1__*.sql`, `V2__*.sql`, etc.). [file:108]
- Docker / Docker Compose para levantar un entorno reproducible. [file:17]
- Scripts Bash para restaurar dump histórico a un schema “legacy” y luego migrar datos al modelo nuevo. [file:18][file:16]

---

## Arquitectura de schemas
La BD se organiza por schemas para separar responsabilidades: [file:108]
- `urb`: modelo “nuevo” normalizado (catálogos, rutas, camiones, POIs, etc.). [file:108]
- `urb_sistema`: tablas del sistema (usuarios y relaciones). [file:108]
- `oldurb` (o equivalente): **solo para staging/migración** desde un dump histórico; no forma parte del modelo final. [file:18]

---

## Estructura del repo (referencia)
> Puede variar según tu carpeta real, pero la idea es esta.

```text
.
├─ db/
│  └─ migrations/                 # Migraciones Flyway (schema)
│     ├─ V1__creacion_db.sql
│     └─ V2__*.sql ...
├─ migrar_datos/                  # Migraciones de datos (one-shot)
│  ├─ V1__*.sql
│  ├─ V2__*.sql
│  └─ V6__*.sql
├─ scripts/
│  ├─ restaurar_dump.sh           # Restaura dump legacy en schema oldurb
│  └─ migrar_datos.sh             # Ejecuta todos los .sql de migrar_datos/
├─ docker-compose.yml
├─ .env
└─ README.md
