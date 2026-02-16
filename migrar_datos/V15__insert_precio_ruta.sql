INSERT INTO urb.tipo_tarifa(nombre) VALUES('adulto estandar');
INSERT INTO urb.precio_ruta(id_ruta,precio,id_tipo_tarifa,id_estado)  SELECT id AS id_ruta,10,1,1 FROM urb.ruta;