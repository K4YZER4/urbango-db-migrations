CREATE OR REPLACE FUNCTION urb.fn_rutas_optima_base(
    lat_o double precision,
    lon_o double precision,
    lat_d double precision,
    lon_d double precision,
    hora_actual time without time zone,
    max_walk_m double precision,
    walk_speed_mps double precision,
    max_transf_m double precision,
    min_transf_m double precision,
    buffer_min integer,
    k_routes integer DEFAULT 10
)
RETURNS TABLE (
    tipo text,
    idruta bigint,
    nombre_ruta text,
    idruta_base bigint,
    idruta_a bigint,
    nombre_ruta_a text,
    idruta_base_a bigint,
    idruta_b bigint,
    nombre_ruta_b text,
    idruta_base_b bigint,
    dist_origen_m double precision,
    dist_transbordo_m double precision,
    dist_destino_m double precision,
    score_m double precision,
    lat_subir double precision,
    lon_subir double precision,
    lat_bajar double precision,
    lon_bajar double precision,
    lat_bajada_transf double precision,
    lon_bajada_transf double precision,
    lat_subida_transf double precision,
    lon_subida_transf double precision,
    hora_leg1 time without time zone,
    hora_leg2 time without time zone,
    metros_transbordo double precision
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH params AS (
    SELECT
      ST_SetSRID(ST_MakePoint(lon_o, lat_o), 4326)::geography AS pto_o,
      ST_SetSRID(ST_MakePoint(lon_d, lat_d), 4326)::geography AS pto_d
  ),

  rutas_cercanas AS (
    SELECT
      r.id AS idruta,
      r.id AS idruta_base,
      r.nombre::text AS nombre_ruta
    FROM urb.ruta r
  ),

  origen_geometria AS (
    SELECT DISTINCT ON (rc.idruta)
      rc.idruta,
      rc.idruta_base,
      rc.nombre_ruta,
      p.latitud::double precision  AS latitud,
      p.longitud::double precision AS longitud,
      p.orden AS orden_base,
      ST_Distance(
        (SELECT pto_o FROM params),
        ST_SetSRID(ST_MakePoint(p.longitud, p.latitud), 4326)::geography
      )::double precision AS dist_o_m
    FROM urb.ruta_base_posicion p
    JOIN rutas_cercanas rc ON rc.idruta = p.id_ruta
    WHERE p.longitud IS NOT NULL
      AND p.latitud IS NOT NULL
      AND ST_DWithin(
        (SELECT pto_o FROM params),
        ST_SetSRID(ST_MakePoint(p.longitud, p.latitud), 4326)::geography,
        max_walk_m
      )
    ORDER BY
      rc.idruta,
      ST_Distance(
        (SELECT pto_o FROM params),
        ST_SetSRID(ST_MakePoint(p.longitud, p.latitud), 4326)::geography
      ) ASC
  ),

  origen AS (
    SELECT
      re.id_ruta AS id_ruta,
      re.id      AS id_ruta_ejecutada,
      og.idruta_base,
      og.nombre_ruta,
      og.latitud,
      og.longitud,
      rp.hora::time AS hora,
      rp.orden,
      og.dist_o_m
    FROM origen_geometria og
    JOIN urb.ruta_ejecutada re ON re.id_ruta = og.idruta
    CROSS JOIN LATERAL (
      SELECT
        rp.hora,
        rp.orden
      FROM urb.ruta_ejecutada_posicion rp
      WHERE rp.id_ruta_ejecutada = re.id
        AND rp.hora::time > hora_actual
        AND ST_DWithin(
          ST_SetSRID(ST_MakePoint(og.longitud, og.latitud), 4326)::geography,
          rp.geom::geography,
          200
        )
      ORDER BY ST_Distance(
        ST_SetSRID(ST_MakePoint(og.longitud, og.latitud), 4326)::geography,
        rp.geom::geography
      ) ASC
      LIMIT 1
    ) rp
    WHERE EXTRACT(EPOCH FROM (rp.hora - hora_actual)) >= CEIL(og.dist_o_m / walk_speed_mps)
  ),

  best_origen AS (
    WITH punto_mas_cercano AS (
      SELECT DISTINCT ON (o.id_ruta_ejecutada)
        o.*,
        CEIL(o.dist_o_m / walk_speed_mps)::integer AS tiempo_caminata_seg
      FROM origen o
      ORDER BY o.id_ruta_ejecutada, o.dist_o_m ASC, o.hora ASC
    ),
    candidatos_mejorados AS (
      SELECT
        pmc.id_ruta_ejecutada,
        o2.id_ruta,
        o2.idruta_base,
        o2.nombre_ruta,
        o2.latitud,
        o2.longitud,
        o2.hora,
        o2.orden,
        o2.dist_o_m,
        CEIL(o2.dist_o_m / walk_speed_mps)::integer AS tiempo_caminata_seg,
        ABS(o2.dist_o_m - pmc.dist_o_m) AS dif_dist,
        pmc.orden - o2.orden AS puntos_antes
      FROM punto_mas_cercano pmc
      JOIN origen o2
        ON o2.id_ruta_ejecutada = pmc.id_ruta_ejecutada
       AND o2.orden < pmc.orden
       AND pmc.orden - o2.orden <= 5
       AND ABS(o2.dist_o_m - pmc.dist_o_m) <= 50
       AND EXTRACT(EPOCH FROM (o2.hora - hora_actual)) >= CEIL(o2.dist_o_m / walk_speed_mps)
    ),
    mejor_candidato AS (
      SELECT DISTINCT ON (cm.id_ruta_ejecutada)
        cm.id_ruta,
        cm.id_ruta_ejecutada,
        cm.idruta_base,
        cm.nombre_ruta,
        cm.latitud,
        cm.longitud,
        cm.hora,
        cm.orden,
        cm.dist_o_m,
        cm.tiempo_caminata_seg
      FROM candidatos_mejorados cm
      ORDER BY
        cm.id_ruta_ejecutada,
        cm.puntos_antes ASC,
        cm.dif_dist ASC,
        cm.hora ASC
    )
    SELECT
      COALESCE(mc.id_ruta, pmc.id_ruta) AS id_ruta,
      COALESCE(mc.id_ruta_ejecutada, pmc.id_ruta_ejecutada) AS id_ruta_ejecutada,
      COALESCE(mc.idruta_base, pmc.idruta_base) AS idruta_base,
      COALESCE(mc.nombre_ruta, pmc.nombre_ruta) AS nombre_ruta,
      COALESCE(mc.latitud, pmc.latitud) AS latitud,
      COALESCE(mc.longitud, pmc.longitud) AS longitud,
      COALESCE(mc.hora, pmc.hora) AS hora,
      COALESCE(mc.orden, pmc.orden) AS orden,
      COALESCE(mc.dist_o_m, pmc.dist_o_m) AS dist_o_m,
      COALESCE(mc.tiempo_caminata_seg, pmc.tiempo_caminata_seg) AS tiempo_caminata_seg
    FROM punto_mas_cercano pmc
    LEFT JOIN mejor_candidato mc ON mc.id_ruta_ejecutada = pmc.id_ruta_ejecutada
  ),

  top_o AS (
    SELECT * FROM best_origen
    ORDER BY dist_o_m ASC, hora ASC
    LIMIT k_routes
  ),

  destino_geometria AS (
    SELECT DISTINCT ON (rc.idruta)
      rc.idruta,
      rc.idruta_base,
      rc.nombre_ruta,
      p.latitud::double precision  AS latitud,
      p.longitud::double precision AS longitud,
      p.orden AS orden_base,
      ST_Distance(
        (SELECT pto_d FROM params),
        ST_SetSRID(ST_MakePoint(p.longitud, p.latitud), 4326)::geography
      )::double precision AS dist_d_m
    FROM urb.ruta_base_posicion p
    JOIN rutas_cercanas rc ON rc.idruta = p.id_ruta
    WHERE p.longitud IS NOT NULL
      AND p.latitud IS NOT NULL
      AND ST_DWithin(
        (SELECT pto_d FROM params),
        ST_SetSRID(ST_MakePoint(p.longitud, p.latitud), 4326)::geography,
        max_walk_m
      )
    ORDER BY
      rc.idruta,
      ST_Distance(
        (SELECT pto_d FROM params),
        ST_SetSRID(ST_MakePoint(p.longitud, p.latitud), 4326)::geography
      ) ASC
  ),

  destino AS (
    SELECT
      re.id_ruta AS id_ruta,
      re.id      AS id_ruta_ejecutada,
      dg.idruta_base,
      dg.nombre_ruta,
      dg.latitud,
      dg.longitud,
      rp.hora::time AS hora,
      rp.orden,
      dg.dist_d_m
    FROM destino_geometria dg
    JOIN urb.ruta_ejecutada re ON re.id_ruta = dg.idruta
    CROSS JOIN LATERAL (
      SELECT
        rp.hora,
        rp.orden
      FROM urb.ruta_ejecutada_posicion rp
      WHERE rp.id_ruta_ejecutada = re.id
        AND ST_DWithin(
          ST_SetSRID(ST_MakePoint(dg.longitud, dg.latitud), 4326)::geography,
          rp.geom::geography,
          200
        )
      ORDER BY ST_Distance(
        ST_SetSRID(ST_MakePoint(dg.longitud, dg.latitud), 4326)::geography,
        rp.geom::geography
      ) ASC
      LIMIT 1
    ) rp
  ),

  best_destino AS (
    SELECT DISTINCT ON (d.id_ruta_ejecutada)
      d.*
    FROM destino d
    ORDER BY d.id_ruta_ejecutada, d.dist_d_m ASC
  ),

  top_d AS (
    SELECT * FROM best_destino
    ORDER BY dist_d_m ASC
    LIMIT k_routes
  ),

  directas AS (
    SELECT
      'directa'::text AS tipo,
      o.id_ruta AS idruta,
      o.nombre_ruta,
      o.idruta_base,
      NULL::bigint AS idruta_a,
      NULL::text AS nombre_ruta_a,
      NULL::bigint AS idruta_base_a,
      NULL::bigint AS idruta_b,
      NULL::text AS nombre_ruta_b,
      NULL::bigint AS idruta_base_b,
      o.dist_o_m AS dist_origen_m,
      0.0::double precision AS dist_transbordo_m,
      d.dist_d_m AS dist_destino_m,
      (o.dist_o_m + d.dist_d_m)::double precision AS score_m,
      o.latitud AS lat_subir,
      o.longitud AS lon_subir,
      d.latitud AS lat_bajar,
      d.longitud AS lon_bajar,
      NULL::double precision AS lat_bajada_transf,
      NULL::double precision AS lon_bajada_transf,
      NULL::double precision AS lat_subida_transf,
      NULL::double precision AS lon_subida_transf,
      o.hora AS hora_leg1,
      d.hora AS hora_leg2,
      NULL::double precision AS metros_transbordo
    FROM top_o o
    JOIN top_d d
      ON d.id_ruta_ejecutada = o.id_ruta_ejecutada
     AND d.orden > o.orden
     AND d.hora > o.hora
  ),

  transbordos AS (
    SELECT
      'transbordo'::text AS tipo,
      NULL::bigint AS idruta,
      NULL::text AS nombre_ruta,
      NULL::bigint AS idruta_base,
      oA.id_ruta AS idruta_a,
      oA.nombre_ruta AS nombre_ruta_a,
      oA.idruta_base AS idruta_base_a,
      B.id_ruta AS idruta_b,
      B.nombre_ruta AS nombre_ruta_b,
      B.idruta_base AS idruta_base_b,
      oA.dist_o_m AS dist_origen_m,
      T.dist_trans_m AS dist_transbordo_m,
      B.dist_d_m AS dist_destino_m,
      (oA.dist_o_m + T.dist_trans_m + B.dist_d_m)::double precision AS score_m,
      oA.latitud AS lat_subir,
      oA.longitud AS lon_subir,
      B.latitud AS lat_bajar,
      B.longitud AS lon_bajar,
      T.lat_bajada_transf,
      T.lon_bajada_transf,
      T.lat_subida_transf,
      T.lon_subida_transf,
      oA.hora AS hora_leg1,
      B.hora AS hora_leg2,
      T.dist_trans_m AS metros_transbordo
    FROM top_o oA
    JOIN (
      SELECT
        dA.id_ruta_ejecutada AS id_ejec_a,
        dA.latitud AS lat_bajada_transf,
        dA.longitud AS lon_bajada_transf,
        dA.hora AS hora_bajada_a,
        dA.orden AS orden_bajada,
        dB.id_ruta_ejecutada AS id_ejec_b,
        dB.latitud AS lat_subida_transf,
        dB.longitud AS lon_subida_transf,
        dB.hora AS hora_subida_b,
        dB.orden AS orden_subida,
        ST_Distance(
          ST_SetSRID(ST_MakePoint(dA.longitud, dA.latitud), 4326)::geography,
          ST_SetSRID(ST_MakePoint(dB.longitud, dB.latitud), 4326)::geography
        )::double precision AS dist_trans_m
      FROM best_destino dA
      CROSS JOIN best_origen dB
      WHERE dA.id_ruta_ejecutada <> dB.id_ruta_ejecutada
        AND ST_Distance(
          ST_SetSRID(ST_MakePoint(dA.longitud, dA.latitud), 4326)::geography,
          ST_SetSRID(ST_MakePoint(dB.longitud, dB.latitud), 4326)::geography
        ) <= max_transf_m
        AND ST_Distance(
          ST_SetSRID(ST_MakePoint(dA.longitud, dA.latitud), 4326)::geography,
          ST_SetSRID(ST_MakePoint(dB.longitud, dB.latitud), 4326)::geography
        ) >= min_transf_m
        AND dB.hora > dA.hora + make_interval(secs => CEIL(
          ST_Distance(
            ST_SetSRID(ST_MakePoint(dA.longitud, dA.latitud), 4326)::geography,
            ST_SetSRID(ST_MakePoint(dB.longitud, dB.latitud), 4326)::geography
          ) / walk_speed_mps
        )::int + (buffer_min * 60))
    ) T ON T.id_ejec_a = oA.id_ruta_ejecutada
    JOIN top_d B
      ON B.id_ruta_ejecutada = T.id_ejec_b
     AND B.orden > T.orden_subida
     AND B.hora > T.hora_subida_b
  )

  SELECT * FROM directas
  UNION ALL
  SELECT * FROM transbordos
  ORDER BY score_m ASC, dist_origen_m ASC
  LIMIT 50;

END;
$$;
