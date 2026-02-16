INSERT INTO urb.numero(numero)
SELECT numero_celular
FROM public.vinculo_dispositivo_cel;