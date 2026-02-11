INSERT INTO stg.poi_antiguo(id,title,categoria,direccion,rating,geom,fecha_actualizacion,horario)
SELECT id,title,categoria,direccion,rating,geom,fecha_actualizacion,horario 
FROM public.urb_poi;