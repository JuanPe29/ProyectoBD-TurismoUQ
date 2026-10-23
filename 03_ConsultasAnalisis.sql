-- =====================================================================
-- TurismoUQ - Script 03: Consultas de analisis (Entrega 1)
--
-- Como se calcula el ingreso en las consultas 2 a 5 y 7:
--   * Ingreso de una reserva = pagos 'exitoso' - movimientos 'reembolsado'
--     (los pagos fallidos y pendientes no son dinero recibido, RN06/RN07).
--   * Primero se agrega PAGO por reserva y despues se une con el
--     alojamiento. Una reserva puede tener varias habitaciones (varias
--     filas en RESERVA_HABITACION); si se une PAGO directamente con
--     RESERVA_HABITACION el pago se cuenta una vez por habitacion.
--     Por eso se usa reserva_alojamiento: UNA fila por reserva con su
--     alojamiento (todas las habitaciones de una reserva son del mismo
--     alojamiento).
-- =====================================================================

SET SQLBLANKLINES ON


-- ---------------------------------------------------------------------
-- 1. Ocupacion por municipio y mes (PIVOT)
--    Noches-habitacion ocupadas (reservas confirmadas o completadas) por
--    municipio y anio, con una columna por mes. Aqui si se usa
--    RESERVA_HABITACION directamente porque cada habitacion ocupada
--    cuenta como ocupacion.
-- ---------------------------------------------------------------------
SELECT *
FROM (
    SELECT
        m.nombre AS municipio,
        EXTRACT(YEAR FROM rh.fecha_entrada) AS anio,
        TO_CHAR(rh.fecha_entrada, 'MM') AS mes,
        rh.fecha_salida - rh.fecha_entrada AS noches
    FROM RESERVA_HABITACION rh
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    JOIN ALOJAMIENTO a
        ON h.id_alojamiento = a.id_alojamiento
    JOIN MUNICIPIO m
        ON a.id_municipio = m.id_municipio
    JOIN RESERVA r
        ON rh.id_reserva = r.id_reserva
    WHERE r.estado IN ('confirmada', 'completada')
)
PIVOT (
    SUM(noches)
    FOR mes IN (
        '01' AS ENE,
        '02' AS FEB,
        '03' AS MAR,
        '04' AS ABR,
        '05' AS MAY,
        '06' AS JUN,
        '07' AS JUL,
        '08' AS AGO,
        '09' AS SEP,
        '10' AS OCT,
        '11' AS NOV,
        '12' AS DIC
    )
)
ORDER BY municipio, anio;


-- ---------------------------------------------------------------------
-- 2. Ingresos por municipio, tipo de alojamiento y temporada (ROLLUP)
--    La temporada de una reserva es la categoria (alta, media, baja) de
--    la temporada en la que cae su check-in. GROUPING distingue las filas
--    de subtotal (1) de las filas de detalle (0).
-- ---------------------------------------------------------------------
WITH pagos_reserva AS (
    SELECT
        id_reserva,
        SUM(CASE WHEN estado = 'exitoso' THEN monto ELSE -monto END) AS ingreso
    FROM PAGO
    WHERE estado IN ('exitoso', 'reembolsado')
    GROUP BY id_reserva
),
reserva_alojamiento AS (
    SELECT
        rh.id_reserva,
        MIN(h.id_alojamiento) AS id_alojamiento
    FROM RESERVA_HABITACION rh
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    GROUP BY rh.id_reserva
),
datos AS (
    SELECT
        m.nombre AS municipio,
        ta.nombre AS tipo_alojamiento,
        t.categoria AS temporada,
        pr.ingreso
    FROM pagos_reserva pr
    JOIN RESERVA r
        ON pr.id_reserva = r.id_reserva
    JOIN reserva_alojamiento ra
        ON pr.id_reserva = ra.id_reserva
    JOIN ALOJAMIENTO a
        ON ra.id_alojamiento = a.id_alojamiento
    JOIN MUNICIPIO m
        ON a.id_municipio = m.id_municipio
    JOIN TIPO_ALOJAMIENTO ta
        ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
    JOIN TEMPORADA t
        ON r.fecha_checkin BETWEEN t.fecha_inicio AND t.fecha_fin
),
resumen AS (
    SELECT
        CASE
            WHEN GROUPING(municipio) = 1
                THEN 'TOTAL GENERAL'
            ELSE municipio
        END AS municipio,

        CASE
            WHEN GROUPING(tipo_alojamiento) = 1
                THEN 'TOTAL'
            ELSE tipo_alojamiento
        END AS tipo_alojamiento,

        CASE
            WHEN GROUPING(temporada) = 1
                THEN 'TOTAL'
            ELSE temporada
        END AS temporada,

        SUM(ingreso) AS ingresos,

        GROUPING(municipio) AS g_municipio,
        GROUPING(tipo_alojamiento) AS g_tipo,
        GROUPING(temporada) AS g_temporada

    FROM datos

    GROUP BY ROLLUP (
        municipio,
        tipo_alojamiento,
        temporada
    )
)
SELECT
    municipio,
    tipo_alojamiento,
    temporada,
    ingresos
FROM resumen
ORDER BY
    g_municipio,
    municipio,
    g_tipo,
    tipo_alojamiento,
    g_temporada,
    temporada;


-- ---------------------------------------------------------------------
-- 3. Los 3 alojamientos de mayor ingreso dentro de cada municipio
--    (RANK con PARTITION BY). El ingreso se agrega primero por reserva y
--    cada reserva se asigna a un solo alojamiento, asi un pago no se
--    cuenta dos veces cuando la reserva tiene varias habitaciones.
-- ---------------------------------------------------------------------
WITH pagos_reserva AS (
    SELECT
        id_reserva,
        SUM(CASE WHEN estado = 'exitoso' THEN monto ELSE -monto END) AS ingreso
    FROM PAGO
    WHERE estado IN ('exitoso', 'reembolsado')
    GROUP BY id_reserva
),
reserva_alojamiento AS (
    SELECT
        rh.id_reserva,
        MIN(h.id_alojamiento) AS id_alojamiento
    FROM RESERVA_HABITACION rh
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    GROUP BY rh.id_reserva
),
ingresos_alojamiento AS (
    SELECT
        m.nombre AS municipio,
        a.id_alojamiento,
        a.nombre_comercial AS alojamiento,
        SUM(pr.ingreso) AS ingreso_total
    FROM pagos_reserva pr
    JOIN reserva_alojamiento ra
        ON pr.id_reserva = ra.id_reserva
    JOIN ALOJAMIENTO a
        ON ra.id_alojamiento = a.id_alojamiento
    JOIN MUNICIPIO m
        ON a.id_municipio = m.id_municipio
    GROUP BY
        m.nombre,
        a.id_alojamiento,
        a.nombre_comercial
),
ranking AS (
    SELECT
        municipio,
        alojamiento,
        ingreso_total,
        RANK() OVER (
            PARTITION BY municipio
            ORDER BY ingreso_total DESC
        ) AS posicion
    FROM ingresos_alojamiento
)
SELECT
    municipio,
    alojamiento,
    ingreso_total,
    posicion
FROM ranking
WHERE posicion <= 3
ORDER BY municipio, posicion;


-- ---------------------------------------------------------------------
-- 4. Variacion de ingresos mes contra mes (LAG)
--    Ingreso neto recibido en cada mes (segun la fecha del pago) y su
--    diferencia absoluta y porcentual contra el mes anterior.
-- ---------------------------------------------------------------------
WITH ingresos_mes AS (
    SELECT
        TRUNC(fecha_pago, 'MM') AS mes,
        SUM(CASE WHEN estado = 'exitoso' THEN monto ELSE -monto END) AS ingreso_mes
    FROM PAGO
    WHERE estado IN ('exitoso', 'reembolsado')
    GROUP BY TRUNC(fecha_pago, 'MM')
),
comparacion AS (
    SELECT
        mes,
        ingreso_mes,
        LAG(ingreso_mes) OVER (
            ORDER BY mes
        ) AS ingreso_mes_anterior
    FROM ingresos_mes
)
SELECT
    TO_CHAR(mes, 'YYYY-MM') AS mes,
    ingreso_mes,
    ingreso_mes_anterior,
    ingreso_mes - ingreso_mes_anterior AS variacion,
    ROUND(100 * (ingreso_mes - ingreso_mes_anterior) / ingreso_mes_anterior, 1) AS variacion_pct
FROM comparacion
ORDER BY mes;


-- ---------------------------------------------------------------------
-- 5. Consulta parametrizada con variables de enlace (rango de fechas)
--    Reservas efectivas (confirmadas o completadas) con check-in dentro
--    del rango, e ingreso neto de esas reservas, por municipio.
--    Para otro rango basta cambiar los EXEC.
-- ---------------------------------------------------------------------
VARIABLE fecha_inicio VARCHAR2(10);
VARIABLE fecha_fin VARCHAR2(10);

EXEC :fecha_inicio := '2025-01-01';
EXEC :fecha_fin := '2025-12-31';

WITH pagos_reserva AS (
    SELECT
        id_reserva,
        SUM(CASE WHEN estado = 'exitoso' THEN monto ELSE -monto END) AS ingreso
    FROM PAGO
    WHERE estado IN ('exitoso', 'reembolsado')
    GROUP BY id_reserva
),
reserva_alojamiento AS (
    SELECT
        rh.id_reserva,
        MIN(h.id_alojamiento) AS id_alojamiento
    FROM RESERVA_HABITACION rh
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    GROUP BY rh.id_reserva
)
SELECT
    m.nombre AS municipio,
    COUNT(*) AS reservas,
    SUM(NVL(pr.ingreso, 0)) AS ingresos
FROM RESERVA r
JOIN reserva_alojamiento ra
    ON r.id_reserva = ra.id_reserva
JOIN ALOJAMIENTO a
    ON ra.id_alojamiento = a.id_alojamiento
JOIN MUNICIPIO m
    ON a.id_municipio = m.id_municipio
LEFT JOIN pagos_reserva pr
    ON r.id_reserva = pr.id_reserva
WHERE r.estado IN ('confirmada', 'completada')
AND r.fecha_checkin >= TO_DATE(:fecha_inicio, 'YYYY-MM-DD')
AND r.fecha_checkin < TO_DATE(:fecha_fin, 'YYYY-MM-DD') + 1
GROUP BY m.nombre
ORDER BY ingresos DESC;


-- ---------------------------------------------------------------------
-- 6. UNPIVOT de reservas por estado
--    Primero se cuenta cuantas reservas de cada estado tiene cada
--    municipio (una columna por estado) y luego UNPIVOT convierte esas
--    columnas en filas. Cada reserva se cuenta una sola vez aunque tenga
--    varias habitaciones.
-- ---------------------------------------------------------------------
WITH reserva_alojamiento AS (
    SELECT
        rh.id_reserva,
        MIN(h.id_alojamiento) AS id_alojamiento
    FROM RESERVA_HABITACION rh
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    GROUP BY rh.id_reserva
)
SELECT
    municipio,
    estado,
    cantidad
FROM (
    SELECT
        m.nombre AS municipio,

        SUM(
            CASE
                WHEN r.estado = 'pendiente' THEN 1
                ELSE 0
            END
        ) AS pendientes,

        SUM(
            CASE
                WHEN r.estado = 'confirmada' THEN 1
                ELSE 0
            END
        ) AS confirmadas,

        SUM(
            CASE
                WHEN r.estado = 'cancelada' THEN 1
                ELSE 0
            END
        ) AS canceladas,

        SUM(
            CASE
                WHEN r.estado = 'completada' THEN 1
                ELSE 0
            END
        ) AS completadas

    FROM RESERVA r

    JOIN reserva_alojamiento ra
        ON r.id_reserva = ra.id_reserva

    JOIN ALOJAMIENTO a
        ON ra.id_alojamiento = a.id_alojamiento

    JOIN MUNICIPIO m
        ON a.id_municipio = m.id_municipio

    GROUP BY m.nombre
)
UNPIVOT (
    cantidad
    FOR estado IN (
        pendientes AS 'PENDIENTE',
        confirmadas AS 'CONFIRMADA',
        canceladas AS 'CANCELADA',
        completadas AS 'COMPLETADA'
    )
)
ORDER BY municipio, estado;


-- ---------------------------------------------------------------------
-- 7. Consulta libre
--    Pregunta de negocio: "Que alojamientos estan peor calificados que
--    el promedio de su tipo de alojamiento, y cuanto dinero mueven?"
--    Sirve a la gerencia para priorizar visitas de control de calidad:
--    primero los que estan mas lejos del promedio de su tipo y que mas
--    ingresos generan (un mal servicio ahi afecta a mas clientes).
--    Solo se consideran alojamientos con al menos 20 resenas para que el
--    promedio sea confiable.
-- ---------------------------------------------------------------------
WITH pagos_reserva AS (
    SELECT
        id_reserva,
        SUM(CASE WHEN estado = 'exitoso' THEN monto ELSE -monto END) AS ingreso
    FROM PAGO
    WHERE estado IN ('exitoso', 'reembolsado')
    GROUP BY id_reserva
),
reserva_alojamiento AS (
    SELECT
        rh.id_reserva,
        MIN(h.id_alojamiento) AS id_alojamiento
    FROM RESERVA_HABITACION rh
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    GROUP BY rh.id_reserva
),
calificacion_alojamiento AS (
    SELECT
        ra.id_alojamiento,
        COUNT(*) AS num_resenas,
        ROUND(AVG(re.calificacion), 2) AS promedio
    FROM RESENA re
    JOIN reserva_alojamiento ra
        ON re.id_reserva = ra.id_reserva
    GROUP BY ra.id_alojamiento
    HAVING COUNT(*) >= 20
),
ingreso_alojamiento AS (
    SELECT
        ra.id_alojamiento,
        SUM(pr.ingreso) AS ingreso_total
    FROM pagos_reserva pr
    JOIN reserva_alojamiento ra
        ON pr.id_reserva = ra.id_reserva
    GROUP BY ra.id_alojamiento
),
comparacion AS (
    SELECT
        ta.nombre AS tipo_alojamiento,
        m.nombre AS municipio,
        a.nombre_comercial AS alojamiento,
        ca.num_resenas,
        ca.promedio,
        ROUND(AVG(ca.promedio) OVER (PARTITION BY ta.nombre), 2) AS promedio_tipo,
        ia.ingreso_total
    FROM calificacion_alojamiento ca
    JOIN ALOJAMIENTO a
        ON ca.id_alojamiento = a.id_alojamiento
    JOIN TIPO_ALOJAMIENTO ta
        ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
    JOIN MUNICIPIO m
        ON a.id_municipio = m.id_municipio
    LEFT JOIN ingreso_alojamiento ia
        ON ca.id_alojamiento = ia.id_alojamiento
)
SELECT
    tipo_alojamiento,
    municipio,
    alojamiento,
    num_resenas,
    promedio,
    promedio_tipo,
    promedio - promedio_tipo AS diferencia,
    ingreso_total
FROM comparacion
WHERE promedio < promedio_tipo
ORDER BY diferencia, ingreso_total DESC;
