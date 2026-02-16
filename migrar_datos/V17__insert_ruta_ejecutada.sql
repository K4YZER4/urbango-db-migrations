INSERT INTO urb.ruta_ejecutada(id_ruta,id_camion,fecha,hora_inicio,hora_fin,fecha_creacion) 
SELECT U.id,pue.idcamion,pue.fecha,pue.horainicio,pue.horafin,fechacreacion 
from public.urb_ruta pur 
INNER JOIN urb.ruta U 
ON U.nombre=pur.nombre 
INNER JOIN public.urb_ruta_ejecutada pue 
ON pur.idruta=pue.idruta;