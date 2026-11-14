-- Script 13: pruebas de seguridad (se conecta con cada usuario)
-- (ejecutar con F5 despues de los scripts 11 y 12)
--
-- Cada seccion se conecta como un usuario distinto y prueba lo que SI puede
-- hacer y lo que NO. Los errores ORA-00942, ORA-01031, ORA-00904 y ORA-01402
-- que aparecen son los esperados: demuestran que el privilegio no existe.
-- (En Oracle 23ai o posterior la falta de privilegio se informa como ORA-41900.)
--
-- Ajustar la cadena de conexion si es necesario (host:puerto/servicio).
 DEFINE conexion = localhost:1522/FREEPDB1

SET SQLBLANKLINES ON
SET LINESIZE 200
SET PAGESIZE 100


-- =====================================================================
-- 1. RECEPCION
-- =====================================================================
CONNECT u_recepcion/Recepcion2026@&conexion
SET SERVEROUTPUT ON

PROMPT 1.1 Roles activos de la sesion
SELECT * FROM SESSION_ROLES;

PROMPT 1.2 SI puede consultar reservas a traves de la vista
SELECT id_reserva, cliente, alojamiento, habitacion, fecha_entrada, estado, pagado
FROM turismouq.v_recep_reservas
WHERE id_cliente = 1234
ORDER BY fecha_entrada;

PROMPT 1.3 NO puede leer las tablas (ORA-00942 esperado)
SELECT COUNT(*) FROM turismouq.RESERVA;
SELECT COUNT(*) FROM turismouq.CLIENTE;

PROMPT 1.4 SI puede registrar un cliente y cambiar su telefono (se deshace con ROLLBACK)
INSERT INTO turismouq.v_recep_clientes (nombre, documento, correo, telefono, ciudad_origen)
VALUES ('Cliente Prueba Seguridad', '999000111', 'prueba.seguridad@correo.com', '3000000000', 'Manizales');

UPDATE turismouq.v_recep_clientes
SET telefono = '3111111111'
WHERE documento = '999000111';

PROMPT 1.5 NO puede cambiar el nombre ni el documento (solo correo, telefono y ciudad) (ORA-01031 esperado; ORA-41900 en Oracle 23ai o posterior)
UPDATE turismouq.v_recep_clientes
SET nombre = 'Otro nombre'
WHERE documento = '999000111';

ROLLBACK;

PROMPT 1.6 NO puede borrar pagos (ORA-01031 esperado; ORA-41900 en Oracle 23ai o posterior)
DELETE FROM turismouq.v_recep_pagos WHERE id_pago = 1;

PROMPT 1.7 SI puede crear una reserva con pago usando el procedimiento
VARIABLE v_reserva_recep NUMBER
DECLARE
    v_hab       NUMBER;
    v_resultado VARCHAR2(20);
BEGIN
    -- Habitacion para 2 personas libre del 08 al 10/12/2026, buscada solo con vistas
    SELECT MIN(h.id_habitacion)
    INTO v_hab
    FROM turismouq.v_recep_habitaciones h
    WHERE h.capacidad_maxima >= 2
      AND NOT EXISTS (SELECT 1
                      FROM turismouq.v_recep_reservas r
                      WHERE r.id_habitacion = h.id_habitacion
                        AND r.estado <> 'cancelada'
                        AND r.fecha_entrada < DATE '2026-12-10'
                        AND r.fecha_salida  > DATE '2026-12-08');

    turismouq.sp_reserva_con_pago(50, v_hab, DATE '2026-12-08', DATE '2026-12-10', 2,
                                  200000, 'tarjeta_debito', :v_reserva_recep, v_resultado);
END;
/

PROMPT 1.8 SI puede registrar un abono y ver el total pagado
INSERT INTO turismouq.v_recep_pagos (id_reserva, fecha_pago, monto, metodo, estado)
VALUES (:v_reserva_recep, SYSDATE, 50000, 'efectivo', 'exitoso');
COMMIT;

SELECT id_reserva, cliente, alojamiento, habitacion, estado, pagado
FROM turismouq.v_recep_reservas
WHERE id_reserva = :v_reserva_recep;


-- =====================================================================
-- 2. ADMINISTRADOR DE ALOJAMIENTO (encargado1 = alojamiento 1)
-- =====================================================================
CONNECT encargado1/Encargado2026@&conexion

PROMPT 2.1 SI ve sus habitaciones, y SOLO las de su alojamiento
SELECT id_alojamiento,
       COUNT(*) AS habitaciones
FROM turismouq.v_admin_habitaciones
GROUP BY id_alojamiento;

PROMPT 2.2 SI ve las reservas de su alojamiento (y solo esas)
SELECT COUNT(*) AS reservas_de_mi_alojamiento
FROM turismouq.v_admin_reservas;

PROMPT 2.3 SI cambia una tarifa de su alojamiento (queda auditado con su usuario)
UPDATE turismouq.v_admin_tarifas
SET precio_noche = precio_noche + 1000
WHERE id_tarifa = (SELECT MIN(id_tarifa) FROM turismouq.v_admin_tarifas);

UPDATE turismouq.v_admin_tarifas
SET precio_noche = precio_noche - 1000
WHERE id_tarifa = (SELECT MIN(id_tarifa) FROM turismouq.v_admin_tarifas);

COMMIT;

PROMPT 2.4 NO puede modificar habitaciones de otro alojamiento (0 filas actualizadas)
UPDATE turismouq.v_admin_habitaciones
SET descripcion = 'Cambio no autorizado'
WHERE id_habitacion = 600;

PROMPT 2.5 NO puede crear una habitacion en otro alojamiento (ORA-01402 WITH CHECK OPTION esperado)
INSERT INTO turismouq.v_admin_habitaciones (id_alojamiento, numero, capacidad_maxima, tipo)
VALUES (2, 'X-01', 2, 'Doble');

PROMPT 2.6 NO puede ver pagos ni tablas (ORA-00942 esperado)
SELECT COUNT(*) FROM turismouq.PAGO;
SELECT COUNT(*) FROM turismouq.HABITACION;

ROLLBACK;


-- =====================================================================
-- 3. GERENTE
-- =====================================================================
CONNECT u_gerente/Gerente2026@&conexion

PROMPT 3.1 SI consulta la ocupacion mensual (vista materializada)
SELECT municipio,
       ROUND(AVG(porcentaje_ocupacion), 1) AS ocupacion_promedio_2025
FROM turismouq.MV_OCUPACION_MENSUAL
WHERE anio = 2025
GROUP BY municipio
ORDER BY ocupacion_promedio_2025 DESC;

PROMPT 3.2 SI consulta clientes por ciudad, sin datos personales
SELECT ciudad_origen, COUNT(*) AS clientes
FROM turismouq.v_gerente_clientes
GROUP BY ciudad_origen
ORDER BY clientes DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT 3.3 NO ve el documento de los clientes (ORA-00904 esperado)
SELECT documento FROM turismouq.v_gerente_clientes WHERE ROWNUM = 1;

PROMPT 3.4 NO puede modificar datos (ORA-01031 esperado; ORA-41900 en Oracle 23ai o posterior)
UPDATE turismouq.RESERVA SET estado = 'cancelada' WHERE id_reserva = 1;
DELETE FROM turismouq.PAGO WHERE id_pago = 1;


-- =====================================================================
-- 4. AUDITOR
-- =====================================================================
CONNECT u_auditor/Auditor2026@&conexion

PROMPT 4.1 SI consulta la auditoria de tarifas (aparece el cambio hecho por ENCARGADO1)
SELECT id_tarifa, operacion, precio_anterior, precio_nuevo, usuario_bd,
       TO_CHAR(fecha_cambio, 'DD/MM/YYYY HH24:MI:SS') AS fecha_cambio
FROM turismouq.AUDITORIA_TARIFA
ORDER BY id_auditoria DESC
FETCH FIRST 4 ROWS ONLY;

PROMPT 4.2 SI consulta los usuarios internos, pero sin la clave
SELECT nombre_usuario, rol, estado
FROM turismouq.v_auditor_usuarios
ORDER BY id_usuario
FETCH FIRST 5 ROWS ONLY;

PROMPT 4.3 NO ve la clave (ORA-00904 esperado) ni la tabla de usuarios (ORA-00942 esperado)
SELECT clave FROM turismouq.v_auditor_usuarios WHERE ROWNUM = 1;
SELECT clave FROM turismouq.USUARIO_SISTEMA WHERE ROWNUM = 1;

PROMPT 4.4 NO puede borrar ni alterar la auditoria (ORA-01031 esperado; ORA-41900 en Oracle 23ai o posterior)
DELETE FROM turismouq.AUDITORIA_TARIFA;
UPDATE turismouq.AUDITORIA_TARIFA SET usuario_bd = 'NADIE';


-- =====================================================================
-- 5. Limpieza (como TURISMOUQ): borra la reserva de prueba de recepcion
-- =====================================================================
CONNECT turismouq/turismouq@&conexion

DELETE FROM PAGO
WHERE id_reserva IN (SELECT id_reserva FROM RESERVA
                     WHERE id_cliente = 50
                       AND fecha_checkin  = DATE '2026-12-08'
                       AND fecha_checkout = DATE '2026-12-10');

DELETE FROM RESERVA_HABITACION
WHERE id_reserva IN (SELECT id_reserva FROM RESERVA
                     WHERE id_cliente = 50
                       AND fecha_checkin  = DATE '2026-12-08'
                       AND fecha_checkout = DATE '2026-12-10');

DELETE FROM RESERVA
WHERE id_cliente = 50
  AND fecha_checkin  = DATE '2026-12-08'
  AND fecha_checkout = DATE '2026-12-10';

COMMIT;
