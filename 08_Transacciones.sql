-- Script 08: transaccion atomica de reserva + pago con SAVEPOINT
-- (ejecutar como TURISMOUQ, con F5 y DBMS_OUTPUT activo)
--
-- La operacion tiene dos partes y cada una es atomica:
--   Parte 1  reserva  = RESERVA + RESERVA_HABITACION (todo o nada)
--   Parte 2  pago     = PAGO exitoso + RESERVA pasa a 'confirmada' (todo o nada)
--
--   SAVEPOINT sp_antes_reserva     <- si falla la parte 1 se vuelve aqui:
--                                     no queda nada (rollback total de la operacion)
--   ... se crea la reserva ...
--   SAVEPOINT sp_reserva_creada    <- si falla la parte 2 se vuelve aqui:
--                                     se deshace solo el pago y la confirmacion,
--                                     la reserva queda 'pendiente' (rollback parcial)
--   ... se registra el pago ...
--   COMMIT
--
-- Por que el rollback parcial es correcto para el negocio: una reserva
-- 'pendiente' es valida sin pagos (el cliente puede abonar despues) y una
-- 'confirmada' debe tener al menos un pago exitoso (RN06). Si el pago falla,
-- la reserva se conserva pendiente en lugar de perder la habitacion.

SET SQLBLANKLINES ON
SET SERVEROUTPUT ON FORMAT WRAPPED
SET LINESIZE 200
SET PAGESIZE 100


-- 1. Procedimiento
CREATE OR REPLACE PROCEDURE sp_reserva_con_pago (
    p_id_cliente    IN  CLIENTE.id_cliente%TYPE,
    p_id_habitacion IN  HABITACION.id_habitacion%TYPE,
    p_fecha_in      IN  DATE,
    p_fecha_out     IN  DATE,
    p_num_huespedes IN  NUMBER,
    p_monto         IN  PAGO.monto%TYPE,
    p_metodo        IN  PAGO.metodo%TYPE,
    p_id_reserva    OUT RESERVA.id_reserva%TYPE,
    p_resultado     OUT VARCHAR2
)
IS
    v_bloqueo      HABITACION.id_habitacion%TYPE;
    v_valor        NUMBER;
    v_id_pago      PAGO.id_pago%TYPE;
    v_total_pagado NUMBER;
BEGIN
    p_id_reserva := NULL;

    SAVEPOINT sp_antes_reserva;

    -- Parte 1: reserva
    -- Bloquea la fila de la habitacion: otra sesion que intente reservar la
    -- misma habitacion espera hasta el COMMIT (ver script 09)
    SELECT id_habitacion
    INTO v_bloqueo
    FROM HABITACION
    WHERE id_habitacion = p_id_habitacion
    FOR UPDATE;

    DBMS_OUTPUT.PUT_LINE('  [1] Habitacion ' || p_id_habitacion
        || ' bloqueada con SELECT ... FOR UPDATE');

    -- Valida fechas, cliente, capacidad y disponibilidad (Entrega 2)
    PKG_TURISMOUQ.sp_crear_reserva(
        p_id_cliente, p_id_habitacion, p_fecha_in, p_fecha_out,
        p_num_huespedes, p_id_reserva
    );

    v_valor := PKG_TURISMOUQ.fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

    SAVEPOINT sp_reserva_creada;
    DBMS_OUTPUT.PUT_LINE('  [2] Reserva ' || p_id_reserva
        || ' creada (pendiente). SAVEPOINT sp_reserva_creada');

    -- Parte 2: pago
    BEGIN
        INSERT INTO PAGO (id_reserva, fecha_pago, monto, metodo, estado)
        VALUES (p_id_reserva, SYSDATE, p_monto, p_metodo, 'exitoso')
        RETURNING id_pago INTO v_id_pago;

        UPDATE RESERVA
        SET estado = 'confirmada'
        WHERE id_reserva = p_id_reserva;

        DBMS_OUTPUT.PUT_LINE('  [3] Pago ' || v_id_pago || ' insertado por '
            || TO_CHAR(p_monto, 'FM999G999G999') || ' y reserva confirmada');

        -- El total pagado no puede superar el valor de la reserva
        SELECT SUM(monto)
        INTO v_total_pagado
        FROM PAGO
        WHERE id_reserva = p_id_reserva
          AND estado = 'exitoso';

        IF v_total_pagado > v_valor THEN
            RAISE_APPLICATION_ERROR(-20041,
                'El pago (' || TO_CHAR(v_total_pagado, 'FM999G999G999')
                || ') supera el valor de la reserva ('
                || TO_CHAR(v_valor, 'FM999G999G999') || ')');
        END IF;

        p_resultado := 'CONFIRMADA';

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback parcial: se deshacen el pago y la confirmacion,
            -- la reserva creada antes del savepoint se conserva
            ROLLBACK TO SAVEPOINT sp_reserva_creada;
            p_resultado := 'PENDIENTE';
            DBMS_OUTPUT.PUT_LINE('  [3] Pago rechazado: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('      ROLLBACK TO SAVEPOINT sp_reserva_creada: '
                || 'se deshace el pago, la reserva ' || p_id_reserva
                || ' queda pendiente');
    END;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  [4] COMMIT. Reserva ' || p_id_reserva || ': ' || p_resultado);

EXCEPTION
    WHEN OTHERS THEN
        -- Fallo la parte 1: no queda nada de la operacion.
        -- Se vuelve al savepoint (no ROLLBACK completo) para no deshacer
        -- trabajo que el llamador tuviera antes de invocar el procedimiento.
        ROLLBACK TO SAVEPOINT sp_antes_reserva;
        p_id_reserva := NULL;
        DBMS_OUTPUT.PUT_LINE('  [X] ROLLBACK TO SAVEPOINT sp_antes_reserva: '
            || 'no se registra ni reserva ni pago');
        RAISE;
END sp_reserva_con_pago;
/

SHOW ERRORS PROCEDURE sp_reserva_con_pago


-- 2. Pruebas
VARIABLE v_hab       NUMBER
VARIABLE v_valor     NUMBER
VARIABLE v_reserva1  NUMBER
VARIABLE v_reserva2  NUMBER
VARIABLE v_reserva3  NUMBER
VARIABLE v_resultado VARCHAR2(20)

-- Habitacion libre del 01/12/2026 al 04/12/2026 para 2 huespedes
BEGIN
    SELECT MIN(h.id_habitacion)
    INTO :v_hab
    FROM HABITACION h
    WHERE h.capacidad_maxima >= 2
      AND NOT EXISTS (
          SELECT 1
          FROM RESERVA_HABITACION rh
          JOIN RESERVA r
              ON r.id_reserva = rh.id_reserva
          WHERE rh.id_habitacion = h.id_habitacion
            AND r.estado <> 'cancelada'
            AND rh.fecha_entrada < DATE '2026-12-07'
            AND rh.fecha_salida  > DATE '2026-12-01'
      );

    :v_valor := PKG_TURISMOUQ.fn_valor_estadia(:v_hab, DATE '2026-12-01', DATE '2026-12-04');

    DBMS_OUTPUT.PUT_LINE('Habitacion de prueba: ' || :v_hab
        || ' - valor de 3 noches: ' || TO_CHAR(:v_valor, 'FM999G999G999'));
END;
/

PROMPT
PROMPT === Prueba 1: todo correcto (anticipo del 50 %) -> reserva confirmada + pago
BEGIN
    sp_reserva_con_pago(10, :v_hab, DATE '2026-12-01', DATE '2026-12-04', 2,
                        ROUND(:v_valor * 0.5), 'tarjeta_credito',
                        :v_reserva1, :v_resultado);
END;
/

PROMPT
PROMPT === Prueba 2: rollback parcial - el pago supera el valor de la reserva
PROMPT     (la reserva se conserva pendiente y el pago se deshace)
BEGIN
    sp_reserva_con_pago(25, :v_hab, DATE '2026-12-04', DATE '2026-12-06', 2,
                        :v_valor * 10, 'PSE',
                        :v_reserva2, :v_resultado);
END;
/

PROMPT
PROMPT === Prueba 3: rollback parcial - metodo de pago invalido (viola ck_pago_metodo)
BEGIN
    sp_reserva_con_pago(30, :v_hab, DATE '2026-12-06', DATE '2026-12-07', 1,
                        100000, 'bitcoin',
                        :v_reserva3, :v_resultado);
END;
/

PROMPT
PROMPT === Prueba 4: rollback total - la habitacion ya esta ocupada (falla la parte 1)
PROMPT     (no se registra ni reserva ni pago; ORA-20003 esperado)
DECLARE
    v_antes     NUMBER;
    v_despues   NUMBER;
    v_reserva   NUMBER;
    v_resultado VARCHAR2(20);
BEGIN
    SELECT COUNT(*) INTO v_antes FROM RESERVA;

    BEGIN
        sp_reserva_con_pago(40, :v_hab, DATE '2026-12-02', DATE '2026-12-03', 1,
                            100000, 'efectivo', v_reserva, v_resultado);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  Error esperado: ' || SQLERRM);
    END;

    SELECT COUNT(*) INTO v_despues FROM RESERVA;
    DBMS_OUTPUT.PUT_LINE('  Reservas antes: ' || v_antes || ' - despues: ' || v_despues);
END;
/

PROMPT
PROMPT === Resultado: prueba 1 confirmada con su pago; pruebas 2 y 3 pendientes SIN pagos
SELECT r.id_reserva,
       r.id_cliente,
       r.estado,
       rh.id_habitacion,
       rh.fecha_entrada,
       rh.fecha_salida,
       (SELECT COUNT(*) FROM PAGO p WHERE p.id_reserva = r.id_reserva) AS pagos,
       (SELECT NVL(SUM(p.monto), 0) FROM PAGO p
        WHERE p.id_reserva = r.id_reserva AND p.estado = 'exitoso') AS pagado
FROM RESERVA r
JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva
WHERE r.id_reserva IN (:v_reserva1, :v_reserva2, :v_reserva3)
ORDER BY r.id_reserva;


-- 3. Limpieza: borra las reservas de prueba para que el script se pueda
--    volver a ejecutar con las mismas fechas
DELETE FROM PAGO
WHERE id_reserva IN (:v_reserva1, :v_reserva2, :v_reserva3);

DELETE FROM RESERVA_HABITACION
WHERE id_reserva IN (:v_reserva1, :v_reserva2, :v_reserva3);

DELETE FROM RESERVA
WHERE id_reserva IN (:v_reserva1, :v_reserva2, :v_reserva3);

COMMIT;
