CREATE OR REPLACE FUNCTION urb.fn_obtener_todas_rutas(
    p_id_ciudad BIGINT
)
RETURNS TABLE (
    idruta BIGINT,
    nombre VARCHAR,
    ciudad VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id_ciudad IS NULL THEN
        RAISE EXCEPTION 'p_id_ciudad es obligatorio'
            USING ERRCODE = '22004'; -- null_value_not_allowed
    END IF;

    RETURN QUERY
    SELECT
        r.id,
        r.nombre,
        m.nombre AS ciudad
    FROM urb.ruta r
    INNER JOIN urb.municipio m ON m.id = r.id_ciudad
    INNER JOIN urb.estado e ON e.id = r.id_estado
    WHERE r.id_ciudad = p_id_ciudad
      AND e.nombre = 'ACTIVO'
    ORDER BY r.id;
END;
$$;
