-- =====================================================================
-- TurismoUQ - Script 05: Disparadores (Entrega 2)
--   A. Auditoria de cambios sobre TARIFA con disparador a nivel de
--      sentencia (quien, cuando, valor anterior y nuevo).
--   B. Disparador a nivel de fila que impide registrar una habitacion
--      en una reserva si se solapa con otra reserva de esa habitacion.
-- Requiere el paquete PKG_TURISMOUQ (script 04).
-- =====================================================================

SET SQLBLANKLINES ON


-- ---------------------------------------------------------------------
-- A. AUDITORIA DE TARIFA
-- ---------------------------------------------------------------------
-- A.1 Tabla de auditoria. No tiene FK a TARIFA para que el registro se
--     conserve aunque la tarifa se borre.
CREATE TABLE AUDITORIA_TARIFA (
    id_auditoria    NUMBER GENERATED ALWAYS AS IDENTITY,
    id_tarifa       NUMBER NOT NULL,
    id_habitacion   NUMBER,
    id_temporada    NUMBER,
    operacion       VARCHAR2(10) NOT NULL,
    precio_anterior NUMBER(12,2),
    precio_nuevo    NUMBER(12,2),
    usuario_bd      VARCHAR2(128) NOT NULL,
    usuario_so      VARCHAR2(128),
    equipo          VARCHAR2(128),
    fecha_cambio    TIMESTAMP NOT NULL,

    CONSTRAINT pk_auditoria_tarifa
        PRIMARY KEY (id_auditoria),

    CONSTRAINT ck_auditoria_operacion
        CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);

COMMENT ON TABLE AUDITORIA_TARIFA IS
'Historial de cambios de TARIFA: quien (usuario BD/SO/equipo), cuando, precio anterior y nuevo';


-- Un disparador de sentencia se ejecuta UNA vez por instruccion y no
-- puede leer :OLD ni :NEW. Por eso la auditoria se arma en tres pasos:
--   1) antes de la sentencia se limpia la lista en memoria del paquete
--   2) por cada fila modificada se guarda su valor anterior y nuevo
--   3) despues de la sentencia (disparador de sentencia) se escriben
--      todos los cambios en AUDITORIA_TARIFA junto con quien y cuando
-- Asi un UPDATE que cambia 500 tarifas deja 500 registros con el mismo
-- usuario y la misma marca de tiempo.

-- A.2 Antes de la sentencia: lista vacia
CREATE OR REPLACE TRIGGER trg_tarifa_aud_inicio
BEFORE INSERT OR UPDATE OR DELETE ON TARIFA
BEGIN
    PKG_TURISMOUQ.g_cambios_tarifa.DELETE;
END;
/

-- A.3 Por cada fila: guardar valor anterior y nuevo
CREATE OR REPLACE TRIGGER trg_tarifa_aud_fila
AFTER INSERT OR UPDATE OF precio_noche OR DELETE ON TARIFA
FOR EACH ROW
DECLARE
    v_i PLS_INTEGER := PKG_TURISMOUQ.g_cambios_tarifa.COUNT + 1;
BEGIN
    -- Un UPDATE que deja el mismo precio no es un cambio
    IF UPDATING AND :OLD.precio_noche = :NEW.precio_noche THEN
        RETURN;
    END IF;

    PKG_TURISMOUQ.g_cambios_tarifa(v_i).id_tarifa       := NVL(:NEW.id_tarifa, :OLD.id_tarifa);
    PKG_TURISMOUQ.g_cambios_tarifa(v_i).id_habitacion   := NVL(:NEW.id_habitacion, :OLD.id_habitacion);
    PKG_TURISMOUQ.g_cambios_tarifa(v_i).id_temporada    := NVL(:NEW.id_temporada, :OLD.id_temporada);
    PKG_TURISMOUQ.g_cambios_tarifa(v_i).precio_anterior := :OLD.precio_noche;
    PKG_TURISMOUQ.g_cambios_tarifa(v_i).precio_nuevo    := :NEW.precio_noche;
    PKG_TURISMOUQ.g_cambios_tarifa(v_i).operacion :=
        CASE
            WHEN INSERTING THEN 'INSERT'
            WHEN UPDATING  THEN 'UPDATE'
            ELSE 'DELETE'
        END;
END;
/

-- A.4 Disparador a nivel de sentencia: registra la auditoria
CREATE OR REPLACE TRIGGER trg_tarifa_auditoria
AFTER INSERT OR UPDATE OR DELETE ON TARIFA
DECLARE
    v_fecha TIMESTAMP := SYSTIMESTAMP;
BEGIN
    FOR i IN 1..PKG_TURISMOUQ.g_cambios_tarifa.COUNT LOOP
        INSERT INTO AUDITORIA_TARIFA (
            id_tarifa, id_habitacion, id_temporada, operacion,
            precio_anterior, precio_nuevo,
            usuario_bd, usuario_so, equipo, fecha_cambio
        )
        VALUES (
            PKG_TURISMOUQ.g_cambios_tarifa(i).id_tarifa,
            PKG_TURISMOUQ.g_cambios_tarifa(i).id_habitacion,
            PKG_TURISMOUQ.g_cambios_tarifa(i).id_temporada,
            PKG_TURISMOUQ.g_cambios_tarifa(i).operacion,
            PKG_TURISMOUQ.g_cambios_tarifa(i).precio_anterior,
            PKG_TURISMOUQ.g_cambios_tarifa(i).precio_nuevo,
            USER,
            SYS_CONTEXT('USERENV', 'OS_USER'),
            SYS_CONTEXT('USERENV', 'HOST'),
            v_fecha
        );
    END LOOP;

    PKG_TURISMOUQ.g_cambios_tarifa.DELETE;
END;
/


-- ---------------------------------------------------------------------
-- B. DISPARADOR DE FILA: EVITAR SOLAPES DE RESERVAS (RN01)
--    Antes de insertar una linea en RESERVA_HABITACION busca otra linea
--    de la misma habitacion, de una reserva no cancelada, cuyas fechas se
--    crucen. Dos rangos [entrada, salida) se cruzan cuando
--        entrada_existente < salida_nueva  Y  salida_existente > entrada_nueva
--    (si una sale el 10 y otra entra el 10 no hay solape).
--    Si la nueva linea pertenece a una reserva cancelada no se valida.
--
--    Es BEFORE INSERT porque un disparador de fila no puede consultar su
--    propia tabla durante un UPDATE (error de tabla mutante ORA-04091);
--    en un INSERT ... VALUES de una sola fila Oracle si lo permite. Las
--    reservas se registran con INSERT ... VALUES (sp_crear_reserva).
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_rh_evitar_solape
BEFORE INSERT ON RESERVA_HABITACION
FOR EACH ROW
DECLARE
    v_estado     RESERVA.estado%TYPE;
    v_solapes    NUMBER;
    v_id_reserva RESERVA.id_reserva%TYPE;
BEGIN
    SELECT estado
    INTO v_estado
    FROM RESERVA
    WHERE id_reserva = :NEW.id_reserva;

    IF v_estado = 'cancelada' THEN
        RETURN;
    END IF;

    SELECT COUNT(*), MIN(rh.id_reserva)
    INTO v_solapes, v_id_reserva
    FROM RESERVA_HABITACION rh
    JOIN RESERVA r
        ON r.id_reserva = rh.id_reserva
    WHERE rh.id_habitacion = :NEW.id_habitacion
      AND r.estado <> 'cancelada'
      AND rh.fecha_entrada < :NEW.fecha_salida
      AND rh.fecha_salida > :NEW.fecha_entrada;

    IF v_solapes > 0 THEN
        RAISE_APPLICATION_ERROR(-20020,
            'La habitacion ' || :NEW.id_habitacion || ' ya esta ocupada entre el '
            || TO_CHAR(:NEW.fecha_entrada, 'DD/MM/YYYY') || ' y el '
            || TO_CHAR(:NEW.fecha_salida, 'DD/MM/YYYY')
            || ' (se cruza con la reserva ' || v_id_reserva || ')');
    END IF;
END;
/

-- Verificacion: los cuatro disparadores deben quedar ENABLED
SELECT trigger_name, trigger_type, triggering_event, table_name, status
FROM USER_TRIGGERS
ORDER BY table_name, trigger_name;
