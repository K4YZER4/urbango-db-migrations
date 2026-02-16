INSERT INTO urb.ruta_base_posicion (id_ruta,latitud,longitud,orden)
SELECT n.id AS id_ruta ,po.latitud AS latitud ,po.longitud AS longitud,po.orden AS orden   
FROM urb.ruta n  
INNER JOIN public.urb_ruta  o  
    ON n.nombre=o.nombre 
INNER JOIN public.urb_ruta_base b 
    ON o.idruta=b.idruta 
INNER JOIN public.urb_ruta_base_posicion po 
    ON po.idruta_base=b.idruta_base;