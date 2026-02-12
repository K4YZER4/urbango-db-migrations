INSERT INTO urb.ruta(nombre,id_ciudad,id_tipo_camion)
SELECT p.nombre,m.id,t.id
FROM public.urb_ruta p
INNER JOIN urb.municipio m
 ON LOWER(m.nombre)=LOWER(p.ciudad)
INNER JOIN urb.tipo_camion t
 ON LOWER(t.nombre)=LOWER(p.tipo_camion);