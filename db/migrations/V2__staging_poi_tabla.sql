CREATE SCHEMA IF NOT EXISTS stg;

CREATE TABLE IF NOT EXISTS stg.poi_antiguo(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  categoria TEXT NOT NULL,
  direccion TEXT NOT NULL,
  rating NUMERIC(3,2) NULL,
  geom geometry(Point, 4326) NOT NULL,
  fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  horario TEXT
);