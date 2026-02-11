INSERT INTO urb.pais(nombre)    VALUES('Mexico');
INSERT INTO urb.estado_localidad(nombre,id_pais)  VALUES('Sinaloa',1);
INSERT INTO urb.municipio(nombre,id_estado_localidad)  VALUES ('Guasave',1);
INSERT INTO urb.codigo_postal(cp,id_municipio)  VALUES (81045,1);