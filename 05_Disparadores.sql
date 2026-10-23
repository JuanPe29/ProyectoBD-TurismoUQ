-- Script 05: disparadores (auditoria de TARIFA y solapes de reservas)

SET SQLBLANKLINES ON


-- A. Auditoria de TARIFA
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


-- El disparador de sentencia no puede leer :OLD ni :NEW, por eso el de
-- fila guarda los cambios en el paquete y el de sentencia los registra.

-- Antes de la sentencia: limpia la lista
CREATE OR REPLACE TRIGGER trg_tarifa_aud_inicio
BEFORE INSERT OR UPDATE OR DELETE ON TARIFA
BEGIN
    PKG_TURISMOUQ.g_cambios_tarifa.DELETE;
END;
/

-- Por cada fila: guarda el precio anterior y el nuevo
CREATE OR REPLACE TRIGGER trg_tarifa_aud_fila
AFTER INSERT OR UPDATE OF precio_noche OR DELETE ON TARIFA
FOR EACH ROW
DECLARE
    v_i PLS_INTEGER := PKG_TURISMOUQ.g_cambios_tarifa.COUNT + 1;
BEGIN
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

-- Disparador de sentencia: escribe la auditoria
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


-- B. Disparador de fila: impide registrar una habitacion en fechas
--    que se cruzan con otra reserva no cancelada
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

-- Verificacion
SELECT trigger_name, trigger_type, triggering_event, table_name, status
FROM USER_TRIGGERS
ORDER BY table_name, trigger_name;
