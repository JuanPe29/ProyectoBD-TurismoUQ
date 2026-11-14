-- Script 09: concurrencia - preparacion del experimento
-- (ejecutar como TURISMOUQ con F5, una sola vez)
--
-- Experimento: dos sesiones intentan reservar la MISMA habitacion (667) para
-- las MISMAS fechas (15/12/2026 al 17/12/2026) al mismo tiempo.
--
--   Experimento 1 - ANTES (sin bloqueo):  PKG_TURISMOUQ.sp_crear_reserva
--   Experimento 2 - DESPUES (con bloqueo): sp_crear_reserva_segura (SELECT ... FOR UPDATE)
--
-- Los pasos de cada sesion estan en:
--   09a_Concurrencia_Sesion1.sql  (por ejemplo, SQL Developer)
--   09b_Concurrencia_Sesion2.sql  (por ejemplo, SQL*Plus u otra conexion de SQL Developer)
-- Cada paso se ejecuta por separado (Ctrl+Enter) siguiendo el numero de paso.
--
-- Por que falla el "antes": Oracle usa lectura consistente (READ COMMITTED):
-- una sesion no ve las filas que otra sesion inserto y aun no confirma.
-- La validacion de disponibilidad de sp_crear_reserva y el disparador
-- trg_rh_evitar_solape hacen un SELECT COUNT(*) que no ve la reserva sin
-- COMMIT de la otra sesion, asi que ambas sesiones ven la habitacion libre,
-- ambas insertan y ambas confirman: queda la habitacion reservada dos veces.
-- Insertar en RESERVA_HABITACION tampoco bloquea, porque son filas nuevas
-- distintas (no hay una fila comun por la que compitan).
--
-- Como lo resuelve el "despues": antes de validar, cada sesion bloquea la
-- fila de la habitacion con SELECT ... FOR UPDATE. La segunda sesion queda
-- esperando (evento "enq: TX - row lock contention") hasta que la primera
-- haga COMMIT o ROLLBACK. Cuando continua, su validacion ya ve la reserva
-- confirmada de la primera y rechaza la segunda con ORA-20003.
-- El bloqueo es solo de esa habitacion: reservar otras habitaciones no espera.

SET SQLBLANKLINES ON
SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100


-- 1. Version segura de la creacion de reservas
CREATE OR REPLACE PROCEDURE sp_crear_reserva_segura (
    p_id_cliente    IN  CLIENTE.id_cliente%TYPE,
    p_id_habitacion IN  HABITACION.id_habitacion%TYPE,
    p_fecha_in      IN  DATE,
    p_fecha_out     IN  DATE,
    p_num_huespedes IN  NUMBER,
    p_id_reserva    OUT RESERVA.id_reserva%TYPE
)
IS
    v_bloqueo HABITACION.id_habitacion%TYPE;
BEGIN
    -- Serializa las reservas de la misma habitacion (espera si otra sesion
    -- tiene la habitacion bloqueada)
    SELECT id_habitacion
    INTO v_bloqueo
    FROM HABITACION
    WHERE id_habitacion = p_id_habitacion
    FOR UPDATE;

    -- Con la fila bloqueada, valida y registra igual que en la Entrega 2.
    -- No hace COMMIT: el bloqueo se libera cuando el llamador confirma.
    PKG_TURISMOUQ.sp_crear_reserva(
        p_id_cliente, p_id_habitacion, p_fecha_in, p_fecha_out,
        p_num_huespedes, p_id_reserva
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005,
            'La habitacion ' || p_id_habitacion || ' no existe');
END sp_crear_reserva_segura;
/

SHOW ERRORS PROCEDURE sp_crear_reserva_segura


-- 2. Limpieza de una ejecucion anterior del experimento
--    (solo las reservas de los clientes 25 y 26 en la habitacion 667 del 15 al 17/12/2026)
DELETE FROM RESERVA_HABITACION
WHERE id_habitacion = 667
  AND id_reserva IN (SELECT id_reserva
                     FROM RESERVA
                     WHERE id_cliente IN (25, 26)
                       AND fecha_checkin  = DATE '2026-12-15'
                       AND fecha_checkout = DATE '2026-12-17');

DELETE FROM RESERVA r
WHERE r.id_cliente IN (25, 26)
  AND r.fecha_checkin  = DATE '2026-12-15'
  AND r.fecha_checkout = DATE '2026-12-17'
  AND NOT EXISTS (SELECT 1 FROM RESERVA_HABITACION rh WHERE rh.id_reserva = r.id_reserva)
  AND NOT EXISTS (SELECT 1 FROM PAGO p WHERE p.id_reserva = r.id_reserva);

COMMIT;


-- 3. Verificacion: la habitacion 667 debe estar libre en esas fechas
SELECT h.id_habitacion,
       a.nombre_comercial,
       h.capacidad_maxima,
       CASE
           WHEN EXISTS (SELECT 1
                        FROM RESERVA_HABITACION rh
                        JOIN RESERVA r ON r.id_reserva = rh.id_reserva
                        WHERE rh.id_habitacion = h.id_habitacion
                          AND r.estado <> 'cancelada'
                          AND rh.fecha_entrada < DATE '2026-12-17'
                          AND rh.fecha_salida  > DATE '2026-12-15')
           THEN 'OCUPADA'
           ELSE 'LIBRE'
       END AS estado_15_al_17_dic
FROM HABITACION h
JOIN ALOJAMIENTO a
    ON a.id_alojamiento = h.id_alojamiento
WHERE h.id_habitacion = 667;
