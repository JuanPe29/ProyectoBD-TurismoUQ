-- Script 07: pruebas de la Entrega 2

SET SQLBLANKLINES ON
SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100

VARIABLE v_habitacion NUMBER
VARIABLE v_reserva    NUMBER


PROMPT
PROMPT =====================================================================
PROMPT 1. fn_valor_estadia
PROMPT =====================================================================

PROMPT 1.1 Tarifas de la habitacion 1 en las temporadas que atraviesa la prueba
SELECT te.nombre, te.categoria, te.fecha_inicio, te.fecha_fin, ta.precio_noche
FROM TARIFA ta
JOIN TEMPORADA te
    ON te.id_temporada = ta.id_temporada
WHERE ta.id_habitacion = 1
  AND te.fecha_fin >= DATE '2025-12-01'
  AND te.fecha_inicio <= DATE '2026-01-12'
ORDER BY te.fecha_inicio;

PROMPT 1.2 Estadia del 14 al 19 de diciembre de 2025 (cruza media -> alta el dia 16)
PROMPT     Esperado: 2 noches en Media Diciembre + 3 noches en Alta Fin de anio
SELECT TO_CHAR(n.noche, 'DD/MM/YYYY') AS noche,
       te.nombre AS temporada,
       ta.precio_noche
FROM (SELECT DATE '2025-12-14' + LEVEL - 1 AS noche
      FROM DUAL
      CONNECT BY LEVEL <= DATE '2025-12-19' - DATE '2025-12-14') n
JOIN TEMPORADA te
    ON n.noche BETWEEN te.fecha_inicio AND te.fecha_fin
JOIN TARIFA ta
    ON ta.id_temporada = te.id_temporada
   AND ta.id_habitacion = 1
ORDER BY n.noche;

SELECT PKG_TURISMOUQ.fn_valor_estadia(1, DATE '2025-12-14', DATE '2025-12-19') AS valor_funcion
FROM DUAL;

PROMPT 1.3 Estadia del 30/12/2025 al 03/01/2026 (cruza de anio: Alta 2025 -> Alta 2026)
SELECT PKG_TURISMOUQ.fn_valor_estadia(1, DATE '2025-12-30', DATE '2026-01-03') AS valor_funcion,
       (SELECT 2 * ta.precio_noche FROM TARIFA ta JOIN TEMPORADA te ON te.id_temporada = ta.id_temporada
        WHERE ta.id_habitacion = 1 AND te.nombre = 'Alta Fin de anio 2025')
     + (SELECT 2 * ta.precio_noche FROM TARIFA ta JOIN TEMPORADA te ON te.id_temporada = ta.id_temporada
        WHERE ta.id_habitacion = 1 AND te.nombre = 'Alta Inicio de anio 2026') AS valor_esperado
FROM DUAL;

PROMPT 1.4 Comparacion con todas las lineas de reserva cargadas:
PROMPT     valor de la funcion vs calculo por tramos de temporada (debe dar 0 diferencias)
WITH por_tramos AS (
    SELECT rh.id_reserva_habitacion,
           SUM((LEAST(rh.fecha_salida, te.fecha_fin + 1)
                - GREATEST(rh.fecha_entrada, te.fecha_inicio)) * ta.precio_noche) AS valor
    FROM RESERVA_HABITACION rh
    JOIN TEMPORADA te
        ON te.fecha_inicio < rh.fecha_salida
       AND te.fecha_fin >= rh.fecha_entrada
    JOIN TARIFA ta
        ON ta.id_habitacion = rh.id_habitacion
       AND ta.id_temporada = te.id_temporada
    GROUP BY rh.id_reserva_habitacion
)
SELECT COUNT(*) AS lineas_revisadas,
       SUM(CASE WHEN PKG_TURISMOUQ.fn_valor_estadia(rh.id_habitacion, rh.fecha_entrada, rh.fecha_salida)
                     <> pt.valor THEN 1 ELSE 0 END) AS diferencias
FROM RESERVA_HABITACION rh
JOIN por_tramos pt
    ON pt.id_reserva_habitacion = rh.id_reserva_habitacion;

PROMPT 1.5 Casos de error (deben mostrar ORA-20001 y ORA-20010)
BEGIN
    DBMS_OUTPUT.PUT_LINE(PKG_TURISMOUQ.fn_valor_estadia(1, DATE '2025-12-19', DATE '2025-12-14'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Check-out antes del check-in -> ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(PKG_TURISMOUQ.fn_valor_estadia(1, DATE '2026-12-30', DATE '2027-01-02'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Noche sin tarifa (2027) -> ' || SQLERRM);
END;
/


PROMPT
PROMPT =====================================================================
PROMPT 2. sp_crear_reserva
PROMPT =====================================================================

PROMPT 2.1 Se busca una habitacion para 2 personas libre del 14 al 19 de diciembre de 2026
BEGIN
    SELECT MIN(h.id_habitacion)
    INTO :v_habitacion
    FROM HABITACION h
    WHERE h.capacidad_maxima = 2
      AND NOT EXISTS (
          SELECT 1
          FROM RESERVA_HABITACION rh
          JOIN RESERVA r
              ON r.id_reserva = rh.id_reserva
          WHERE rh.id_habitacion = h.id_habitacion
            AND r.estado <> 'cancelada'
            AND rh.fecha_entrada < DATE '2026-12-19'
            AND rh.fecha_salida > DATE '2026-12-14');
END;
/
PRINT v_habitacion

PROMPT 2.2 Caso correcto: cliente 10, 2 huespedes
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(10, :v_habitacion, DATE '2026-12-14', DATE '2026-12-19', 2, :v_reserva);
    COMMIT;
END;
/

SELECT r.id_reserva, r.id_cliente, r.fecha_reserva, r.fecha_checkin, r.fecha_checkout, r.estado,
       rh.id_habitacion, rh.num_huespedes
FROM RESERVA r
JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva
WHERE r.id_reserva = :v_reserva;

PROMPT 2.3 Check-out igual al check-in (debe dar ORA-20001)
DECLARE
    v_id NUMBER;
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(10, :v_habitacion, DATE '2026-12-20', DATE '2026-12-20', 1, v_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

PROMPT 2.4 Capacidad excedida: 3 huespedes en habitacion para 2 (debe dar ORA-20002)
DECLARE
    v_id NUMBER;
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(10, :v_habitacion, DATE '2026-12-20', DATE '2026-12-22', 3, v_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

PROMPT 2.5 Habitacion no disponible: se cruza con la reserva del caso 2.2 (debe dar ORA-20003)
DECLARE
    v_id NUMBER;
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(25, :v_habitacion, DATE '2026-12-17', DATE '2026-12-21', 1, v_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

PROMPT 2.6 Cliente inexistente (debe dar ORA-20004)
DECLARE
    v_id NUMBER;
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(999999, :v_habitacion, DATE '2026-12-20', DATE '2026-12-22', 1, v_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

PROMPT 2.7 Check-in en el pasado (debe dar ORA-20006)
DECLARE
    v_id NUMBER;
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(10, :v_habitacion, DATE '2025-01-10', DATE '2025-01-12', 1, v_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

PROMPT 2.8 Salida que coincide con la entrada de otra reserva: NO es solape (debe crearse)
VARIABLE v_reserva2 NUMBER
BEGIN
    PKG_TURISMOUQ.sp_crear_reserva(25, :v_habitacion, DATE '2026-12-19', DATE '2026-12-21', 1, :v_reserva2);
    COMMIT;
END;
/


PROMPT
PROMPT =====================================================================
PROMPT 3. Disparador de fila trg_rh_evitar_solape (caso real con datos cargados)
PROMPT =====================================================================

PROMPT 3.1 Linea real de una reserva completada (la primera de la habitacion 1)
SELECT rh.id_reserva, rh.id_habitacion, rh.fecha_entrada, rh.fecha_salida, r.estado
FROM RESERVA_HABITACION rh
JOIN RESERVA r
    ON r.id_reserva = rh.id_reserva
WHERE rh.id_reserva_habitacion = (
    SELECT MIN(rh2.id_reserva_habitacion)
    FROM RESERVA_HABITACION rh2
    JOIN RESERVA r2
        ON r2.id_reserva = rh2.id_reserva
    WHERE rh2.id_habitacion = 1
      AND r2.estado = 'completada');

PROMPT 3.2 INSERT directo (sin pasar por el procedimiento) de otra reserva que se
PROMPT     cruza con esa estadia: el disparador lo impide con ORA-20020
DECLARE
    v_entrada DATE;
    v_salida  DATE;
    v_nueva   NUMBER;
BEGIN
    SELECT rh.fecha_entrada, rh.fecha_salida
    INTO v_entrada, v_salida
    FROM RESERVA_HABITACION rh
    WHERE rh.id_reserva_habitacion = (
        SELECT MIN(rh2.id_reserva_habitacion)
        FROM RESERVA_HABITACION rh2
        JOIN RESERVA r2
            ON r2.id_reserva = rh2.id_reserva
        WHERE rh2.id_habitacion = 1
          AND r2.estado = 'completada');

    INSERT INTO RESERVA (id_cliente, fecha_reserva, fecha_checkin, fecha_checkout, estado)
    VALUES (50, v_entrada - 10, v_entrada, v_salida + 1, 'confirmada')
    RETURNING id_reserva INTO v_nueva;

    INSERT INTO RESERVA_HABITACION (id_reserva, id_habitacion, fecha_entrada, fecha_salida, num_huespedes)
    VALUES (v_nueva, 1, v_entrada, v_salida + 1, 1);

    DBMS_OUTPUT.PUT_LINE('ERROR: el disparador no bloqueo el solape');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        ROLLBACK;
END;
/

PROMPT 3.3 Verificacion global: solapes entre reservas no canceladas (debe ser 0)
SELECT COUNT(*) AS solapes
FROM RESERVA_HABITACION a
JOIN RESERVA_HABITACION b
    ON a.id_habitacion = b.id_habitacion
   AND a.id_reserva_habitacion < b.id_reserva_habitacion
   AND a.fecha_entrada < b.fecha_salida
   AND b.fecha_entrada < a.fecha_salida
JOIN RESERVA ra ON ra.id_reserva = a.id_reserva
JOIN RESERVA rb ON rb.id_reserva = b.id_reserva
WHERE ra.estado <> 'cancelada'
  AND rb.estado <> 'cancelada';


PROMPT
PROMPT =====================================================================
PROMPT 4. Cursor con parametros: liquidacion mensual (julio de 2026)
PROMPT =====================================================================

EXEC PKG_TURISMOUQ.sp_liquidacion_mensual(2026, 7);

PROMPT 4.1 Los 10 alojamientos con mayor facturacion en el mes
SELECT *
FROM (
    SELECT a.nombre_comercial, l.num_reservas, l.noches_vendidas, l.valor_estadias,
           l.valor_servicios, l.valor_total, l.comision, l.valor_neto
    FROM LIQUIDACION_MENSUAL l
    JOIN ALOJAMIENTO a
        ON a.id_alojamiento = l.id_alojamiento
    WHERE l.anio = 2026
      AND l.mes = 7
    ORDER BY l.valor_total DESC
)
WHERE ROWNUM <= 10;

PROMPT 4.2 Control: reservas completadas con check-out en julio 2026 (debe coincidir con la suma)
SELECT (SELECT SUM(num_reservas) FROM LIQUIDACION_MENSUAL WHERE anio = 2026 AND mes = 7) AS liquidadas,
       (SELECT COUNT(*) FROM RESERVA
        WHERE estado = 'completada'
          AND fecha_checkout >= DATE '2026-07-01'
          AND fecha_checkout <  DATE '2026-08-01') AS esperadas
FROM DUAL;

PROMPT 4.3 Mes invalido (debe dar ORA-20030)
BEGIN
    PKG_TURISMOUQ.sp_liquidacion_mensual(2026, 13);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/


PROMPT
PROMPT =====================================================================
PROMPT 5. Disparador de sentencia: auditoria de TARIFA
PROMPT =====================================================================

PROMPT 5.1 Se sube 5% la tarifa de temporada alta 2026 de la habitacion 1 (5 filas)
UPDATE TARIFA
SET precio_noche = ROUND(precio_noche * 1.05, -3)
WHERE id_habitacion = 1
  AND id_temporada IN (SELECT id_temporada FROM TEMPORADA
                       WHERE categoria = 'alta' AND anio = 2026);

PROMPT 5.2 Un UPDATE que deja el mismo precio no genera auditoria
UPDATE TARIFA
SET precio_noche = precio_noche
WHERE id_habitacion = 2;

PROMPT 5.3 Se devuelve la tarifa a su valor original (otras 5 filas de auditoria)
UPDATE TARIFA
SET precio_noche = ROUND(precio_noche / 1.05, -3)
WHERE id_habitacion = 1
  AND id_temporada IN (SELECT id_temporada FROM TEMPORADA
                       WHERE categoria = 'alta' AND anio = 2026);

COMMIT;

PROMPT 5.4 Registro de auditoria: quien, cuando, valor anterior y nuevo
SELECT a.id_auditoria, a.id_tarifa, t.nombre AS temporada, a.operacion,
       a.precio_anterior, a.precio_nuevo, a.usuario_bd, a.usuario_so,
       TO_CHAR(a.fecha_cambio, 'DD/MM/YYYY HH24:MI:SS') AS fecha_cambio
FROM AUDITORIA_TARIFA a
JOIN TEMPORADA t
    ON t.id_temporada = a.id_temporada
ORDER BY a.id_auditoria;


PROMPT
PROMPT =====================================================================
PROMPT 6. Vista materializada MV_OCUPACION_MENSUAL
PROMPT =====================================================================

PROMPT 6.1 Ocupacion por municipio en 2025, calculada desde la vista
SELECT municipio,
       SUM(noches_ocupadas) AS noches_ocupadas,
       SUM(noches_disponibles) AS noches_disponibles,
       ROUND(100 * SUM(noches_ocupadas) / SUM(noches_disponibles), 2) AS porcentaje_ocupacion
FROM MV_OCUPACION_MENSUAL
WHERE anio = 2025
GROUP BY municipio
ORDER BY porcentaje_ocupacion DESC;

PROMPT 6.2 Comportamiento del refresco: se confirma la reserva de prueba del caso 2.2
PROMPT     (5 noches en diciembre 2026). Antes del refresco la vista no la ve.
SELECT noches_ocupadas AS antes_de_confirmar
FROM MV_OCUPACION_MENSUAL
WHERE id_alojamiento = (SELECT id_alojamiento FROM HABITACION WHERE id_habitacion = :v_habitacion)
  AND anio = 2026 AND mes = 12;

UPDATE RESERVA SET estado = 'confirmada' WHERE id_reserva = :v_reserva;
COMMIT;

SELECT noches_ocupadas AS confirmada_sin_refrescar
FROM MV_OCUPACION_MENSUAL
WHERE id_alojamiento = (SELECT id_alojamiento FROM HABITACION WHERE id_habitacion = :v_habitacion)
  AND anio = 2026 AND mes = 12;

EXEC DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');

SELECT noches_ocupadas AS despues_de_refrescar
FROM MV_OCUPACION_MENSUAL
WHERE id_alojamiento = (SELECT id_alojamiento FROM HABITACION WHERE id_habitacion = :v_habitacion)
  AND anio = 2026 AND mes = 12;

PROMPT 6.3 Politica de refresco configurada
SELECT mview_name, refresh_method, last_refresh_date FROM USER_MVIEWS;
SELECT rname AS grupo_refresco, next_date AS proximo_refresco, interval FROM USER_REFRESH;


PROMPT
PROMPT =====================================================================
PROMPT 7. Tablespace del historico
PROMPT =====================================================================
SELECT table_name, tablespace_name
FROM USER_TABLES
WHERE table_name IN ('RESERVA', 'RESERVA_HISTORICO');

SELECT EXTRACT(YEAR FROM fecha_checkout) AS anio, estado, COUNT(*) AS reservas,
       SUM(valor_pagado) AS valor_pagado
FROM RESERVA_HISTORICO
GROUP BY EXTRACT(YEAR FROM fecha_checkout), estado
ORDER BY 1, 2;


PROMPT
PROMPT =====================================================================
PROMPT Limpieza: se borran las reservas de prueba y se refresca la vista
PROMPT =====================================================================
DELETE FROM RESERVA_HABITACION WHERE id_reserva IN (:v_reserva, :v_reserva2);
DELETE FROM RESERVA WHERE id_reserva IN (:v_reserva, :v_reserva2);
COMMIT;
EXEC DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
