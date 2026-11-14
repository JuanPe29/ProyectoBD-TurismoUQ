-- Script 09a: concurrencia - SESION 1 (conectado como TURISMOUQ)
--
-- Abrir dos conexiones distintas como TURISMOUQ (por ejemplo, dos hojas de
-- SQL Developer con "Unshared SQL Worksheet" / Ctrl+Shift+N, o SQL Developer
-- y SQL*Plus). Ejecutar los pasos en el orden indicado alternando con
-- 09b_Concurrencia_Sesion2.sql: seleccionar el bloque del paso y ejecutarlo
-- (F5 sobre la seleccion). Activar DBMS_OUTPUT en ambas sesiones.
-- Requisito: haber ejecutado 09_Concurrencia.sql.

SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100


-- =====================================================================
-- EXPERIMENTO 1 - ANTES: sp_crear_reserva sin bloqueo
-- =====================================================================

-- PASO 1 (Sesion 1): reserva la habitacion 667 y NO confirma
DECLARE
    v_reserva NUMBER;
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(25, 667, DATE '2026-12-15', DATE '2026-12-17', 2, v_reserva);
    DBMS_OUTPUT.PUT_LINE('Sesion 1: reserva ' || v_reserva || ' creada SIN COMMIT a las '
        || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3'));
END;
/

-- >>> Ahora ejecutar el PASO 2 en la Sesion 2 (no se bloquea y tambien reserva)

-- PASO 3 (Sesion 1): confirma
COMMIT;

-- >>> Ahora ejecutar el PASO 4 en la Sesion 2 (COMMIT)

-- PASO 5 (Sesion 1): resultado -> la habitacion 667 quedo reservada DOS veces
SELECT r.id_reserva,
       r.id_cliente,
       r.estado,
       rh.id_habitacion,
       rh.fecha_entrada,
       rh.fecha_salida
FROM RESERVA r
JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva
WHERE rh.id_habitacion = 667
  AND r.estado <> 'cancelada'
  AND rh.fecha_entrada < DATE '2026-12-17'
  AND rh.fecha_salida  > DATE '2026-12-15'
ORDER BY r.id_reserva;

-- PASO 6 (Sesion 1): borra la doble reserva para hacer el experimento 2
DELETE FROM RESERVA_HABITACION
WHERE id_habitacion = 667
  AND id_reserva IN (SELECT id_reserva FROM RESERVA
                     WHERE id_cliente IN (25, 26)
                       AND fecha_checkin  = DATE '2026-12-15'
                       AND fecha_checkout = DATE '2026-12-17');

DELETE FROM RESERVA r
WHERE r.id_cliente IN (25, 26)
  AND r.fecha_checkin  = DATE '2026-12-15'
  AND r.fecha_checkout = DATE '2026-12-17'
  AND NOT EXISTS (SELECT 1 FROM RESERVA_HABITACION rh WHERE rh.id_reserva = r.id_reserva);

COMMIT;


-- =====================================================================
-- EXPERIMENTO 2 - DESPUES: sp_crear_reserva_segura con SELECT ... FOR UPDATE
-- =====================================================================

-- PASO 7 (Sesion 1): bloquea la habitacion 667, reserva y NO confirma
DECLARE
    v_reserva NUMBER;
BEGIN
    sp_crear_reserva_segura(25, 667, DATE '2026-12-15', DATE '2026-12-17', 2, v_reserva);
    DBMS_OUTPUT.PUT_LINE('Sesion 1: reserva ' || v_reserva || ' creada SIN COMMIT a las '
        || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || ' (habitacion 667 bloqueada)');
END;
/

-- >>> Ahora ejecutar el PASO 8 en la Sesion 2: se queda esperando

-- PASO 9 (Sesion 1): evidencia del bloqueo mientras la Sesion 2 espera
-- Sesion bloqueada, quien la bloquea, evento de espera y sentencia
SELECT s.sid,
       s.serial#,
       s.username,
       s.status,
       s.blocking_session,
       s.event,
       s.seconds_in_wait,
       q.sql_text
FROM V$SESSION s
LEFT JOIN V$SQL q
    ON q.sql_id = s.sql_id
   AND q.child_number = s.sql_child_number
WHERE s.username = 'TURISMOUQ'
  AND s.blocking_session IS NOT NULL;

-- Bloqueos: TX = bloqueo de fila (la Sesion 1 lo tiene, la Sesion 2 lo pide),
-- TM = bloqueo de tabla en modo compartido (no impide trabajar con otras filas)
SELECT l.sid,
       l.type,
       DECODE(l.lmode, 0, 'ninguno', 2, 'row share (RS)', 3, 'row exclusive (RX)',
                       4, 'share', 6, 'exclusive', l.lmode) AS modo_tenido,
       DECODE(l.request, 0, '-', 6, 'exclusive (espera)', l.request) AS modo_pedido,
       o.object_name,
       l.block AS bloquea_a_otra
FROM V$LOCK l
JOIN V$SESSION s
    ON s.sid = l.sid
LEFT JOIN USER_OBJECTS o
    ON o.object_id = l.id1
   AND l.type = 'TM'
WHERE s.username = 'TURISMOUQ'
  AND (l.type = 'TX' OR o.object_name IN ('HABITACION', 'RESERVA', 'RESERVA_HABITACION'))
ORDER BY l.sid, l.type, o.object_name;

-- PASO 10 (Sesion 1): confirma y libera el bloqueo
-- >>> la Sesion 2 continua de inmediato y recibe ORA-20003
COMMIT;

-- >>> Ahora ejecutar el PASO 11 en la Sesion 2

-- PASO 12 (Sesion 1): resultado -> una sola reserva de la habitacion 667
SELECT r.id_reserva,
       r.id_cliente,
       r.estado,
       rh.id_habitacion,
       rh.fecha_entrada,
       rh.fecha_salida
FROM RESERVA r
JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva
WHERE rh.id_habitacion = 667
  AND r.estado <> 'cancelada'
  AND rh.fecha_entrada < DATE '2026-12-17'
  AND rh.fecha_salida  > DATE '2026-12-15'
ORDER BY r.id_reserva;

-- PASO 13 (Sesion 1): limpieza final del experimento
DELETE FROM RESERVA_HABITACION
WHERE id_habitacion = 667
  AND id_reserva IN (SELECT id_reserva FROM RESERVA
                     WHERE id_cliente IN (25, 26)
                       AND fecha_checkin  = DATE '2026-12-15'
                       AND fecha_checkout = DATE '2026-12-17');

DELETE FROM RESERVA r
WHERE r.id_cliente IN (25, 26)
  AND r.fecha_checkin  = DATE '2026-12-15'
  AND r.fecha_checkout = DATE '2026-12-17'
  AND NOT EXISTS (SELECT 1 FROM RESERVA_HABITACION rh WHERE rh.id_reserva = r.id_reserva);

COMMIT;
