-- Script 06: tablespace del historico y vista materializada

SET SQLBLANKLINES ON


-- A. Tablespace para el historico de reservas (datos de anios cerrados
--    que ya no cambian: crecen aparte y se pueden dejar en solo lectura)
CREATE TABLESPACE ts_historico_reservas
    DATAFILE 'ts_historico_reservas01.dbf'
    SIZE 20M
    AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

-- Tabla del historico dentro del nuevo tablespace
CREATE TABLE RESERVA_HISTORICO (
    id_reserva       NUMBER NOT NULL,
    id_cliente       NUMBER NOT NULL,
    id_alojamiento   NUMBER NOT NULL,
    fecha_reserva    DATE NOT NULL,
    fecha_checkin    DATE NOT NULL,
    fecha_checkout   DATE NOT NULL,
    estado           VARCHAR2(20) NOT NULL,
    num_habitaciones NUMBER NOT NULL,
    noches           NUMBER NOT NULL,
    valor_pagado     NUMBER(14,2) NOT NULL,
    fecha_archivo    DATE DEFAULT SYSDATE NOT NULL,

    CONSTRAINT pk_reserva_historico
        PRIMARY KEY (id_reserva)
        USING INDEX TABLESPACE ts_historico_reservas,

    CONSTRAINT ck_historico_estado
        CHECK (estado IN ('completada', 'cancelada'))
)
TABLESPACE ts_historico_reservas;

COMMENT ON TABLE RESERVA_HISTORICO IS
'Historico de reservas finalizadas de anios cerrados (tablespace ts_historico_reservas)';

-- Se archivan las reservas finalizadas de 2024 y 2025
INSERT INTO RESERVA_HISTORICO (
    id_reserva, id_cliente, id_alojamiento, fecha_reserva, fecha_checkin,
    fecha_checkout, estado, num_habitaciones, noches, valor_pagado
)
WITH pagos_reserva AS (
    SELECT id_reserva,
           SUM(CASE WHEN estado = 'exitoso' THEN monto ELSE -monto END) AS pagado
    FROM PAGO
    WHERE estado IN ('exitoso', 'reembolsado')
    GROUP BY id_reserva
)
SELECT r.id_reserva,
       r.id_cliente,
       MIN(h.id_alojamiento),
       r.fecha_reserva,
       r.fecha_checkin,
       r.fecha_checkout,
       r.estado,
       COUNT(*),
       SUM(rh.fecha_salida - rh.fecha_entrada),
       NVL(MAX(pr.pagado), 0)
FROM RESERVA r
JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva
JOIN HABITACION h
    ON h.id_habitacion = rh.id_habitacion
LEFT JOIN pagos_reserva pr
    ON pr.id_reserva = r.id_reserva
WHERE r.estado IN ('completada', 'cancelada')
  AND r.fecha_checkout < DATE '2026-01-01'
GROUP BY r.id_reserva, r.id_cliente, r.fecha_reserva, r.fecha_checkin,
         r.fecha_checkout, r.estado;

COMMIT;

-- Verificacion
SELECT segment_name, segment_type, tablespace_name, bytes / 1024 / 1024 AS mb
FROM USER_SEGMENTS
WHERE tablespace_name = 'TS_HISTORICO_RESERVAS';


-- B. Vista materializada de ocupacion mensual por alojamiento
--    Refresco completo diario a las 2:00 a.m.: es un reporte de gerencia,
--    ON COMMIT haria lentas las reservas y la consulta no permite FAST.
CREATE MATERIALIZED VIEW MV_OCUPACION_MENSUAL
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH TRUNC(SYSDATE) + 1 + 2/24
NEXT TRUNC(SYSDATE) + 1 + 2/24
AS
WITH rango AS (
    SELECT TRUNC(MIN(fecha_inicio), 'MM') AS desde,
           TRUNC(MAX(fecha_fin), 'MM') AS hasta
    FROM TEMPORADA
),
meses AS (
    SELECT ADD_MONTHS(r.desde, LEVEL - 1) AS inicio_mes
    FROM rango r
    CONNECT BY ADD_MONTHS(r.desde, LEVEL - 1) <= r.hasta
),
capacidad AS (
    SELECT id_alojamiento,
           COUNT(*) AS habitaciones
    FROM HABITACION
    GROUP BY id_alojamiento
),
ocupacion AS (
    SELECT h.id_alojamiento,
           me.inicio_mes,
           COUNT(DISTINCT rh.id_reserva) AS reservas,
           SUM(LEAST(rh.fecha_salida, ADD_MONTHS(me.inicio_mes, 1))
               - GREATEST(rh.fecha_entrada, me.inicio_mes)) AS noches_ocupadas
    FROM RESERVA_HABITACION rh
    JOIN RESERVA r
        ON r.id_reserva = rh.id_reserva
    JOIN HABITACION h
        ON h.id_habitacion = rh.id_habitacion
    JOIN meses me
        ON rh.fecha_entrada < ADD_MONTHS(me.inicio_mes, 1)
       AND rh.fecha_salida > me.inicio_mes
    WHERE r.estado IN ('confirmada', 'completada')
    GROUP BY h.id_alojamiento, me.inicio_mes
)
SELECT a.id_alojamiento,
       a.nombre_comercial AS alojamiento,
       m.nombre AS municipio,
       ta.nombre AS tipo_alojamiento,
       EXTRACT(YEAR FROM me.inicio_mes) AS anio,
       EXTRACT(MONTH FROM me.inicio_mes) AS mes,
       c.habitaciones,
       c.habitaciones * (ADD_MONTHS(me.inicio_mes, 1) - me.inicio_mes) AS noches_disponibles,
       NVL(o.noches_ocupadas, 0) AS noches_ocupadas,
       NVL(o.reservas, 0) AS reservas,
       ROUND(100 * NVL(o.noches_ocupadas, 0)
             / (c.habitaciones * (ADD_MONTHS(me.inicio_mes, 1) - me.inicio_mes)), 2)
           AS porcentaje_ocupacion
FROM ALOJAMIENTO a
JOIN MUNICIPIO m
    ON m.id_municipio = a.id_municipio
JOIN TIPO_ALOJAMIENTO ta
    ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
JOIN capacidad c
    ON c.id_alojamiento = a.id_alojamiento
CROSS JOIN meses me
LEFT JOIN ocupacion o
    ON o.id_alojamiento = a.id_alojamiento
   AND o.inicio_mes = me.inicio_mes;

COMMENT ON MATERIALIZED VIEW MV_OCUPACION_MENSUAL IS
'Ocupacion mensual por alojamiento; refresco completo diario a las 2:00 a.m.';

-- Verificacion
SELECT mview_name, refresh_method, refresh_mode, last_refresh_date
FROM USER_MVIEWS;

SELECT rname AS grupo_refresco, next_date AS proximo_refresco
FROM USER_REFRESH;
