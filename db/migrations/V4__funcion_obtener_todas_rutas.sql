CREATE OR REPLACE FUNCTION urb.fn_obtener_todas_rutas(
    p_id_ciudad BIGINT 
)
RETURNS TABLE (
    idruta BIGINT,
    nombre VARCHAR,
    ciudad VARCHAR,
    idruta_base BIGINT,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id AS idruta,
        r.nombre,
        m.nombre AS ciudad,
        rb.id AS idruta_base,
        rb.fecha_creacion
    FROM urb.ruta r
    LEFT JOIN urb.municipio m
        ON m.id = r.id_ciudad
    LEFT JOIN urb.ruta_base rb 
        ON rb.id_ruta = r.id
        AND rb.activa = true
    WHERE (p_id_ciudad IS NULL OR r.id_ciudad = p_id_ciudad)
    ORDER BY r.id;
END;
$$;
