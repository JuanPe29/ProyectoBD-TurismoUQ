-- Script 03: consultas de analisis
-- Ingreso = pagos exitosos - reembolsos. Los pagos se agregan primero por
-- reserva (reserva_alojamiento) para no contarlos una vez por habitacion.

SET SQLBLANKLINES ON


-- 1. Ocupacion (noches) por municipio y mes - PIVOT
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


-- 2. Ingresos por municipio, tipo de alojamiento y temporada - ROLLUP y GROUPING
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


-- 3. Top 3 alojamientos por ingreso en cada municipio - RANK con PARTITION BY
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


-- 4. Variacion de ingresos mes contra mes - LAG
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


-- 5. Reservas e ingresos por municipio en un rango de fechas - variables de enlace
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


-- 6. Reservas por estado en cada municipio - UNPIVOT
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


-- 7. Pregunta de negocio: que alojamientos estan peor calificados que el
--    promedio de su tipo y cuanto dinero mueven? (minimo 20 resenas)
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
