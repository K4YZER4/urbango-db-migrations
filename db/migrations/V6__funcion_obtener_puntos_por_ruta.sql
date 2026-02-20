CREATE OR REPLACE FUNCTION urb.fn_obtener_puntos_por_ruta_base(
    p_idruta BIGINT
)
RETURNS TABLE (
    latitud  DOUBLE PRECISION,
    longitud DOUBLE PRECISION,
    orden    INT,
    nombre   VARCHAR(150)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.latitud, 
        p.longitud, 
        p.orden, 
        r.nombre 
    FROM urb.ruta_base_posicion p
    JOIN urb.ruta r
        ON r.id = p.id_ruta
    WHERE p.id_ruta = p_idruta
    ORDER BY p.orden ASC;
END;
$$;
