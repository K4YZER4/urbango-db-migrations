INSERT INTO urb.ruta_ejecutada_posicion(id_ruta_ejecutada,latitud,longitud,hora,orden,geom) 
SELECT ur.id,urp.latitud,urp.longitud,urp.hora,urp.orden,urp.geom 
FROM public.urb_ruta_ejecutada pure 
INNER JOIN public.urb_ruta pur 
ON pur.idruta=pure.idruta 
INNER JOIN public.urb_ruta_posicion urp 
ON urp.idrutaejecutada = pure.idrutaejecutada 
INNER JOIN urb.ruta ur 
ON ur.nombre=pur.nombre;