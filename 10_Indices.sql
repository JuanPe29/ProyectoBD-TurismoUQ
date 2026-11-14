-- Script 10: indices - 3 consultas lentas, plan antes/despues y medicion
-- (ejecutar como TURISMOUQ con F5)
--
-- Consultas elegidas (se ejecutan muchas veces al dia en la operacion):
--   Q1 Disponibilidad de una habitacion en un rango de fechas. Es la misma
--      validacion de sp_crear_reserva y del disparador trg_rh_evitar_solape,
--      asi que corre en CADA reserva nueva.
--      -> indice COMPUESTO idx_rh_hab_fechas (id_habitacion, fecha_entrada, fecha_salida)
--   Q2 Cierre de caja: pagos recibidos en un dia. Los pagos operativos se
--      guardan con hora (SYSDATE), por eso se compara TRUNC(fecha_pago).
--      -> indice BASADO EN FUNCION idx_pago_dia (TRUNC(fecha_pago))
--   Q3 Estado de cuenta de un cliente (sus reservas y lo pagado de cada una).
--      Oracle no crea indices sobre las llaves foraneas: RESERVA.id_cliente y
--      PAGO.id_reserva no tienen indice y cada consulta recorre ambas tablas.
--      -> idx_reserva_cliente (id_cliente) y compuesto idx_pago_reserva (id_reserva, estado)
--   Q4 Caso donde el indice NO ayuda: reservas completadas por estado.
--      -> idx_reserva_estado (estado)
--
-- Evidencia:
--   * EXPLAIN PLAN: plan estimado (operacion y costo) antes y despues.
--   * DBMS_XPLAN.DISPLAY_CURSOR con GATHER_PLAN_STATISTICS: plan REAL con
--     filas reales (A-Rows), tiempo (A-Time) y bloques leidos (Buffers).
--   * MEDICION_INDICE: cada consulta ejecutada 500 veces con parametros
--     distintos, antes y despues, con tiempo y lecturas logicas.
--
-- SERVEROUTPUT queda apagado: DISPLAY_CURSOR debe leer la ultima consulta
-- ejecutada y no la llamada interna a DBMS_OUTPUT.

SET SQLBLANKLINES ON
SET SERVEROUTPUT OFF
SET LINESIZE 200
SET PAGESIZE 200


-- 0. Preparacion (permite volver a ejecutar el script)
BEGIN
    FOR i IN (SELECT index_name
              FROM USER_INDEXES
              WHERE index_name IN ('IDX_RH_HAB_FECHAS', 'IDX_PAGO_DIA',
                                   'IDX_RESERVA_CLIENTE', 'IDX_PAGO_RESERVA',
                                   'IDX_RESERVA_ESTADO')) LOOP
        EXECUTE IMMEDIATE 'DROP INDEX ' || i.index_name;
    END LOOP;

    EXECUTE IMMEDIATE 'DROP TABLE MEDICION_INDICE PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- Resultados de la medicion (500 ejecuciones por consulta y fase)
CREATE TABLE MEDICION_INDICE (
    fase             VARCHAR2(10) NOT NULL,
    consulta         VARCHAR2(60) NOT NULL,
    ejecuciones      NUMBER NOT NULL,
    ms_total         NUMBER(10,1) NOT NULL,
    lecturas_logicas NUMBER NOT NULL,
    fecha_medicion   DATE DEFAULT SYSDATE NOT NULL,

    CONSTRAINT pk_medicion_indice
        PRIMARY KEY (fase, consulta),

    CONSTRAINT ck_medicion_fase
        CHECK (fase IN ('ANTES', 'DESPUES'))
);

COMMENT ON TABLE MEDICION_INDICE IS
'Tiempo y lecturas logicas de las consultas del script 10 antes y despues de crear los indices';

-- Procedimiento de medicion: ejecuta cada consulta 500 veces con
-- parametros distintos y guarda el tiempo y las lecturas logicas
-- ('session logical reads' de V$MYSTAT = bloques leidos de memoria o disco)
CREATE OR REPLACE PROCEDURE sp_medir_indices (p_fase IN VARCHAR2)
IS
    c_n CONSTANT PLS_INTEGER := 500;
    v_t0      TIMESTAMP;
    v_r0      NUMBER;
    v_num     NUMBER;
    v_suma    NUMBER;

    FUNCTION lecturas RETURN NUMBER IS
        v NUMBER;
    BEGIN
        SELECT m.value
        INTO v
        FROM V$MYSTAT m
        JOIN V$STATNAME n
            ON n.statistic# = m.statistic#
        WHERE n.name = 'session logical reads';
        RETURN v;
    END;

    PROCEDURE iniciar IS
    BEGIN
        v_t0 := SYSTIMESTAMP;
        v_r0 := lecturas;
    END;

    PROCEDURE registrar (p_consulta IN VARCHAR2) IS
        v_int INTERVAL DAY TO SECOND := SYSTIMESTAMP - v_t0;
        v_lec NUMBER := lecturas - v_r0;
    BEGIN
        DELETE FROM MEDICION_INDICE
        WHERE fase = p_fase
          AND consulta = p_consulta;

        INSERT INTO MEDICION_INDICE (fase, consulta, ejecuciones, ms_total, lecturas_logicas)
        VALUES (p_fase, p_consulta, c_n,
                ROUND((EXTRACT(MINUTE FROM v_int) * 60 + EXTRACT(SECOND FROM v_int)) * 1000, 1),
                v_lec);
    END;
BEGIN
    -- Q1: una habitacion distinta en cada ejecucion
    iniciar;
    FOR i IN 1..c_n LOOP
        SELECT COUNT(*)
        INTO v_num
        FROM RESERVA_HABITACION rh
        JOIN RESERVA r
            ON r.id_reserva = rh.id_reserva
        WHERE rh.id_habitacion = MOD(i, 700) + 1
          AND r.estado <> 'cancelada'
          AND rh.fecha_entrada < DATE '2026-07-20'
          AND rh.fecha_salida  > DATE '2026-07-15';
    END LOOP;
    registrar('Q1 disponibilidad habitacion');

    -- Q2: un dia distinto de 2025 en cada ejecucion
    iniciar;
    FOR i IN 1..c_n LOOP
        FOR f IN (SELECT metodo, COUNT(*) AS pagos, SUM(monto) AS total
                  FROM PAGO
                  WHERE TRUNC(fecha_pago) = DATE '2025-01-01' + MOD(i, 365)
                    AND estado = 'exitoso'
                  GROUP BY metodo) LOOP
            NULL;
        END LOOP;
    END LOOP;
    registrar('Q2 cierre de caja del dia');

    -- Q3: un cliente distinto en cada ejecucion
    iniciar;
    FOR i IN 1..c_n LOOP
        FOR f IN (SELECT r.id_reserva, r.fecha_checkin, r.estado,
                         NVL(SUM(p.monto), 0) AS pagado
                  FROM RESERVA r
                  LEFT JOIN PAGO p
                      ON p.id_reserva = r.id_reserva
                     AND p.estado = 'exitoso'
                  WHERE r.id_cliente = MOD(i * 7, 3000) + 1
                  GROUP BY r.id_reserva, r.fecha_checkin, r.estado) LOOP
            NULL;
        END LOOP;
    END LOOP;
    registrar('Q3 estado de cuenta cliente');

    -- Q4: el optimizador decide el plan
    iniciar;
    FOR i IN 1..c_n LOOP
        SELECT COUNT(*), SUM(fecha_checkout - fecha_checkin)
        INTO v_num, v_suma
        FROM RESERVA
        WHERE estado = 'completada';
    END LOOP;
    registrar('Q4 completadas (no ayuda)');

    -- Q4 obligando a usar el indice con un hint (solo tiene sentido despues)
    IF p_fase = 'DESPUES' THEN
        iniciar;
        FOR i IN 1..c_n LOOP
            SELECT /*+ INDEX(r idx_reserva_estado) */
                   COUNT(*), SUM(fecha_checkout - fecha_checkin)
            INTO v_num, v_suma
            FROM RESERVA r
            WHERE estado = 'completada';
        END LOOP;
        registrar('Q4 completadas forzando indice');
    END IF;

    COMMIT;
END sp_medir_indices;
/

SHOW ERRORS PROCEDURE sp_medir_indices

-- Estadisticas actualizadas para que el optimizador decida con datos reales.
-- En RESERVA.estado se pide un histograma: los estados estan muy
-- desbalanceados (82 % completadas) y el optimizador debe saberlo.
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'RESERVA_HABITACION');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PAGO');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'RESERVA',
        method_opt => 'FOR ALL COLUMNS SIZE AUTO FOR COLUMNS estado SIZE 254');
END;
/

SELECT table_name, num_rows, blocks
FROM USER_TABLES
WHERE table_name IN ('RESERVA', 'RESERVA_HABITACION', 'PAGO')
ORDER BY table_name;


-- =====================================================================
-- 1. ANTES de los indices
-- =====================================================================

-- Q1 Disponibilidad de la habitacion 350 del 15 al 20 de julio de 2026
EXPLAIN PLAN FOR
SELECT COUNT(*)
FROM RESERVA_HABITACION rh
JOIN RESERVA r
    ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = 350
  AND r.estado <> 'cancelada'
  AND rh.fecha_entrada < DATE '2026-07-20'
  AND rh.fecha_salida  > DATE '2026-07-15';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ /* Q1 antes */ COUNT(*)
FROM RESERVA_HABITACION rh
JOIN RESERVA r
    ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = 350
  AND r.estado <> 'cancelada'
  AND rh.fecha_entrada < DATE '2026-07-20'
  AND rh.fecha_salida  > DATE '2026-07-15';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));


-- Q2 Cierre de caja del 15 de julio de 2025
EXPLAIN PLAN FOR
SELECT metodo, COUNT(*) AS pagos, SUM(monto) AS total
FROM PAGO
WHERE TRUNC(fecha_pago) = DATE '2025-07-15'
  AND estado = 'exitoso'
GROUP BY metodo;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ /* Q2 antes */ metodo, COUNT(*) AS pagos, SUM(monto) AS total
FROM PAGO
WHERE TRUNC(fecha_pago) = DATE '2025-07-15'
  AND estado = 'exitoso'
GROUP BY metodo;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));


-- Q3 Estado de cuenta del cliente 1234
EXPLAIN PLAN FOR
SELECT r.id_reserva, r.fecha_checkin, r.estado, NVL(SUM(p.monto), 0) AS pagado
FROM RESERVA r
LEFT JOIN PAGO p
    ON p.id_reserva = r.id_reserva
   AND p.estado = 'exitoso'
WHERE r.id_cliente = 1234
GROUP BY r.id_reserva, r.fecha_checkin, r.estado
ORDER BY r.fecha_checkin;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ /* Q3 antes */
       r.id_reserva, r.fecha_checkin, r.estado, NVL(SUM(p.monto), 0) AS pagado
FROM RESERVA r
LEFT JOIN PAGO p
    ON p.id_reserva = r.id_reserva
   AND p.estado = 'exitoso'
WHERE r.id_cliente = 1234
GROUP BY r.id_reserva, r.fecha_checkin, r.estado
ORDER BY r.fecha_checkin;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));


-- Q4 Reservas completadas y noches vendidas
EXPLAIN PLAN FOR
SELECT COUNT(*), SUM(fecha_checkout - fecha_checkin)
FROM RESERVA
WHERE estado = 'completada';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Medicion de 500 ejecuciones sin indices
EXEC sp_medir_indices('ANTES')


-- =====================================================================
-- 2. Creacion de los indices
-- =====================================================================

-- Compuesto: primero la columna de igualdad (id_habitacion) y luego las de
-- rango (fechas). Asi el indice llega directo a las lineas de UNA habitacion
-- y dentro de ellas filtra por fecha sin ir a la tabla.
CREATE INDEX idx_rh_hab_fechas
    ON RESERVA_HABITACION (id_habitacion, fecha_entrada, fecha_salida);

-- Basado en funcion: un indice normal sobre fecha_pago NO se puede usar
-- cuando la columna esta dentro de TRUNC(); este indice guarda ya calculado
-- TRUNC(fecha_pago) y se usa con la misma expresion de la consulta.
CREATE INDEX idx_pago_dia
    ON PAGO (TRUNC(fecha_pago));

-- Llaves foraneas sin indice (Oracle no los crea solo). El de PAGO es
-- compuesto: con (id_reserva, estado) el filtro estado = 'exitoso' se
-- resuelve en el indice.
CREATE INDEX idx_reserva_cliente
    ON RESERVA (id_cliente);

CREATE INDEX idx_pago_reserva
    ON PAGO (id_reserva, estado);

-- Indice que NO ayuda (caso Q4)
CREATE INDEX idx_reserva_estado
    ON RESERVA (estado);

-- Estadisticas de la columna virtual del indice basado en funcion
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PAGO',
        method_opt => 'FOR ALL HIDDEN COLUMNS SIZE AUTO');
END;
/

SELECT index_name, table_name, index_type, distinct_keys, clustering_factor
FROM USER_INDEXES
WHERE index_name IN ('IDX_RH_HAB_FECHAS', 'IDX_PAGO_DIA', 'IDX_RESERVA_CLIENTE',
                     'IDX_PAGO_RESERVA', 'IDX_RESERVA_ESTADO')
ORDER BY table_name, index_name;

SELECT index_name, column_expression
FROM USER_IND_EXPRESSIONS
WHERE index_name = 'IDX_PAGO_DIA';


-- =====================================================================
-- 3. DESPUES de los indices (mismas consultas)
-- =====================================================================

-- Q1
EXPLAIN PLAN FOR
SELECT COUNT(*)
FROM RESERVA_HABITACION rh
JOIN RESERVA r
    ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = 350
  AND r.estado <> 'cancelada'
  AND rh.fecha_entrada < DATE '2026-07-20'
  AND rh.fecha_salida  > DATE '2026-07-15';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ /* Q1 despues */ COUNT(*)
FROM RESERVA_HABITACION rh
JOIN RESERVA r
    ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = 350
  AND r.estado <> 'cancelada'
  AND rh.fecha_entrada < DATE '2026-07-20'
  AND rh.fecha_salida  > DATE '2026-07-15';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));


-- Q2
EXPLAIN PLAN FOR
SELECT metodo, COUNT(*) AS pagos, SUM(monto) AS total
FROM PAGO
WHERE TRUNC(fecha_pago) = DATE '2025-07-15'
  AND estado = 'exitoso'
GROUP BY metodo;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ /* Q2 despues */ metodo, COUNT(*) AS pagos, SUM(monto) AS total
FROM PAGO
WHERE TRUNC(fecha_pago) = DATE '2025-07-15'
  AND estado = 'exitoso'
GROUP BY metodo;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));


-- Q3
EXPLAIN PLAN FOR
SELECT r.id_reserva, r.fecha_checkin, r.estado, NVL(SUM(p.monto), 0) AS pagado
FROM RESERVA r
LEFT JOIN PAGO p
    ON p.id_reserva = r.id_reserva
   AND p.estado = 'exitoso'
WHERE r.id_cliente = 1234
GROUP BY r.id_reserva, r.fecha_checkin, r.estado
ORDER BY r.fecha_checkin;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ /* Q3 despues */
       r.id_reserva, r.fecha_checkin, r.estado, NVL(SUM(p.monto), 0) AS pagado
FROM RESERVA r
LEFT JOIN PAGO p
    ON p.id_reserva = r.id_reserva
   AND p.estado = 'exitoso'
WHERE r.id_cliente = 1234
GROUP BY r.id_reserva, r.fecha_checkin, r.estado
ORDER BY r.fecha_checkin;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));


-- =====================================================================
-- 4. Caso donde el indice NO ayuda: Q4 con idx_reserva_estado
-- =====================================================================
-- El 82 % de las reservas estan completadas. Para traer 23.000 de 28.000
-- filas con el indice habria que leer el indice y luego ir a la tabla fila
-- por fila (un bloque por acceso, muchas veces el mismo bloque). Un FULL
-- SCAN lee la tabla completa una sola vez, en lecturas de varios bloques.
-- El optimizador lo sabe (histograma de estado) y NO usa el indice.

PROMPT Distribucion de RESERVA.estado (selectividad)
SELECT estado,
       COUNT(*) AS reservas,
       ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (), 1) AS porcentaje
FROM RESERVA
GROUP BY estado
ORDER BY reservas DESC;

-- 4.1 Con el indice creado el optimizador sigue eligiendo TABLE ACCESS FULL
EXPLAIN PLAN FOR
SELECT COUNT(*), SUM(fecha_checkout - fecha_checkin)
FROM RESERVA
WHERE estado = 'completada';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ /* Q4 normal */ COUNT(*), SUM(fecha_checkout - fecha_checkin)
FROM RESERVA
WHERE estado = 'completada';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- 4.2 Obligando a usar el indice: mas costo y mas bloques leidos que el full scan
EXPLAIN PLAN FOR
SELECT /*+ INDEX(r idx_reserva_estado) */ COUNT(*), SUM(fecha_checkout - fecha_checkin)
FROM RESERVA r
WHERE estado = 'completada';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS INDEX(r idx_reserva_estado) */ /* Q4 forzado */
       COUNT(*), SUM(fecha_checkout - fecha_checkin)
FROM RESERVA r
WHERE estado = 'completada';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- 4.3 El mismo indice SI sirve para un valor poco frecuente (pendiente = 2 %):
--     la utilidad depende de la selectividad del valor, no de la columna
EXPLAIN PLAN FOR
SELECT COUNT(*), SUM(fecha_checkout - fecha_checkin)
FROM RESERVA
WHERE estado = 'pendiente';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Medicion de 500 ejecuciones con los indices
EXEC sp_medir_indices('DESPUES')


-- =====================================================================
-- 5. Comparacion final (500 ejecuciones de cada consulta)
-- =====================================================================
SELECT consulta,
       antes_ms,
       despues_ms,
       ROUND(100 * (1 - despues_ms / NULLIF(antes_ms, 0)), 1) AS mejora_tiempo_pct,
       ROUND(antes_lec / ejecuciones, 1)   AS lecturas_por_ejec_antes,
       ROUND(despues_lec / ejecuciones, 1) AS lecturas_por_ejec_despues
FROM (
    SELECT consulta, fase, ejecuciones, ms_total, lecturas_logicas
    FROM MEDICION_INDICE
)
PIVOT (
    MAX(ms_total) AS ms,
    MAX(lecturas_logicas) AS lec
    FOR fase IN ('ANTES' AS antes, 'DESPUES' AS despues)
)
ORDER BY consulta;
