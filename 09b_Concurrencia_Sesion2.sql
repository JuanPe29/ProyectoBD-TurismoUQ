-- Script 09b: concurrencia - SESION 2 (conectado como TURISMOUQ, en otra conexion)
--
-- Ejecutar cada paso cuando lo indique 09a_Concurrencia_Sesion1.sql.

SET SERVEROUTPUT ON
SET LINESIZE 200
SET TIMING ON


-- =====================================================================
-- EXPERIMENTO 1 - ANTES: sp_crear_reserva sin bloqueo
-- =====================================================================

-- PASO 2 (Sesion 2): reserva la MISMA habitacion y fechas mientras la
-- Sesion 1 no ha confirmado. No espera: la validacion no ve la reserva sin
-- COMMIT de la Sesion 1, asi que la habitacion "parece" libre.
DECLARE
    v_reserva NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Sesion 2: inicio ' || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3'));
    PKG_TURISMOUQ.sp_crear_reserva(26, 667, DATE '2026-12-15', DATE '2026-12-17', 1, v_reserva);
    DBMS_OUTPUT.PUT_LINE('Sesion 2: reserva ' || v_reserva || ' creada a las '
        || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || ' (sin esperar)');
END;
/

-- PASO 4 (Sesion 2): confirma -> doble reserva de la habitacion 667
COMMIT;


-- =====================================================================
-- EXPERIMENTO 2 - DESPUES: sp_crear_reserva_segura con SELECT ... FOR UPDATE
-- =====================================================================

-- PASO 8 (Sesion 2): intenta reservar la misma habitacion.
-- Se queda ESPERANDO en el SELECT ... FOR UPDATE hasta que la Sesion 1
-- haga COMMIT (paso 10). Al continuar, la validacion ya ve la reserva
-- confirmada y responde ORA-20003. El tiempo de espera queda en "Elapsed".
DECLARE
    v_reserva NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Sesion 2: inicio ' || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3'));
    sp_crear_reserva_segura(26, 667, DATE '2026-12-15', DATE '2026-12-17', 1, v_reserva);
    DBMS_OUTPUT.PUT_LINE('Sesion 2: reserva ' || v_reserva || ' creada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Sesion 2: desbloqueada a las '
            || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3'));
        DBMS_OUTPUT.PUT_LINE('Sesion 2: ' || SQLERRM);
END;
/

-- PASO 11 (Sesion 2): no hay nada que confirmar
ROLLBACK;
