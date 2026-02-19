CREATE OR REPLACE FUNCTION urb.fn_rutas_interpoladas_api(
    intervalo_metros NUMERIC
)
RETURNS TABLE (
    ruta_id BIGINT,
    id_ruta_base BIGINT,
    idx INTEGER,
    latitud DOUBLE PRECISION,
    longitud DOUBLE PRECISION
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH rutas_geom AS (
        SELECT
            p.id_ruta AS ruta_id,
            ST_MakeLine(
                ST_SetSRID(ST_MakePoint(p.longitud, p.latitud), 4326)
                ORDER BY p.orden
            ) AS geom
        FROM urb.ruta_base_posicion p
        GROUP BY p.id_ruta
    )
    SELECT
        rg.ruta_id,
        rb.id AS id_ruta_base,
        row_number() OVER (PARTITION BY rg.ruta_id ORDER BY foo.frac)::integer AS idx,
        ST_Y(ST_LineInterpolatePoint(rg.geom, foo.frac))::double precision AS latitud,
        ST_X(ST_LineInterpolatePoint(rg.geom, foo.frac))::double precision AS longitud
    FROM rutas_geom rg
    LEFT JOIN urb.ruta_base rb
        ON rb.id_ruta = rg.ruta_id
        AND rb.activa = true
    CROSS JOIN LATERAL (
        SELECT
            (gs.i / ST_Length(rg.geom::geography)) AS frac
        FROM generate_series(
            0::numeric,
            ST_Length(rg.geom::geography)::numeric,
            intervalo_metros::numeric
        ) AS gs(i)
    ) AS foo
    ORDER BY rg.ruta_id, idx;
END;
$$;
