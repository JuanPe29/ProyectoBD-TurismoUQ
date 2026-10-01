-- 1. Ocupacion por municipio y mes

SELECT *
FROM (
    SELECT
        m.nombre AS municipio,
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
ORDER BY municipio;

-- 2. Ingresos por municipio, tipo y temporada

WITH pagos_reserva AS (
    SELECT
        id_reserva,
        SUM(monto) AS ingreso
    FROM PAGO
    WHERE estado = 'exitoso'
    GROUP BY id_reserva
),
datos AS (
    SELECT
        pr.id_reserva,
        m.nombre AS municipio,
        ta.nombre AS tipo_alojamiento,
        t.nombre AS temporada,
        pr.ingreso
    FROM pagos_reserva pr
    JOIN RESERVA r
        ON pr.id_reserva = r.id_reserva
    JOIN RESERVA_HABITACION rh
        ON r.id_reserva = rh.id_reserva
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    JOIN ALOJAMIENTO a
        ON h.id_alojamiento = a.id_alojamiento
    JOIN MUNICIPIO m
        ON a.id_municipio = m.id_municipio
    JOIN TIPO_ALOJAMIENTO ta
        ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
    JOIN TEMPORADA t
        ON r.fecha_checkin BETWEEN t.fecha_inicio AND t.fecha_fin
    GROUP BY
        pr.id_reserva,
        m.nombre,
        ta.nombre,
        t.nombre,
        pr.ingreso
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
    

-- 3. Top 3 alojamientos por municipio

WITH pagos_reserva AS (
    SELECT
        id_reserva,
        SUM(monto) AS ingreso
    FROM PAGO
    WHERE estado = 'exitoso'
    GROUP BY id_reserva
),
ingresos_alojamiento AS (
    SELECT
        m.nombre AS municipio,
        a.id_alojamiento,
        a.nombre_comercial AS alojamiento,
        SUM(pr.ingreso) AS ingreso_total
    FROM pagos_reserva pr
    JOIN RESERVA_HABITACION rh
        ON pr.id_reserva = rh.id_reserva
    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion
    JOIN ALOJAMIENTO a
        ON h.id_alojamiento = a.id_alojamiento
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

-- 4. Variacion de ingresos mes contra mes

WITH ingresos_mes AS (
    SELECT
        TRUNC(fecha_pago, 'MM') AS mes,
        SUM(monto) AS ingreso_mes
    FROM PAGO
    WHERE estado = 'exitoso'
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
    ingreso_mes - ingreso_mes_anterior AS variacion
FROM comparacion
ORDER BY mes;


-- 5. Consulta parametrizada por rango de fechas

VARIABLE fecha_inicio VARCHAR2(10);
VARIABLE fecha_fin VARCHAR2(10);

EXEC :fecha_inicio := '2025-01-01';
EXEC :fecha_fin := '2025-12-31';

SELECT
    m.nombre AS municipio,
    COUNT(DISTINCT r.id_reserva) AS reservas,
    SUM(p.monto) AS ingresos
FROM PAGO p
JOIN RESERVA r
    ON p.id_reserva = r.id_reserva
JOIN RESERVA_HABITACION rh
    ON r.id_reserva = rh.id_reserva
JOIN HABITACION h
    ON rh.id_habitacion = h.id_habitacion
JOIN ALOJAMIENTO a
    ON h.id_alojamiento = a.id_alojamiento
JOIN MUNICIPIO m
    ON a.id_municipio = m.id_municipio
WHERE p.estado = 'exitoso'
AND p.fecha_pago >= TO_DATE(:fecha_inicio, 'YYYY-MM-DD')
AND p.fecha_pago < TO_DATE(:fecha_fin, 'YYYY-MM-DD') + 1
GROUP BY m.nombre
ORDER BY ingresos DESC;

-- 6. UNPIVOT de reservas por estado

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

    JOIN RESERVA_HABITACION rh
        ON r.id_reserva = rh.id_reserva

    JOIN HABITACION h
        ON rh.id_habitacion = h.id_habitacion

    JOIN ALOJAMIENTO a
        ON h.id_alojamiento = a.id_alojamiento

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

-- 7. Servicios mas contratados

SELECT
    s.nombre AS servicio,
    a.nombre_comercial AS alojamiento,
    SUM(rs.cantidad) AS veces_contratado,
    SUM(rs.cantidad * s.precio) AS ingreso_servicio
FROM RESERVA_SERVICIO rs
JOIN SERVICIO s
    ON rs.id_servicio = s.id_servicio
JOIN ALOJAMIENTO a
    ON s.id_alojamiento = a.id_alojamiento
GROUP BY
    s.id_servicio,
    s.nombre,
    a.nombre_comercial
ORDER BY veces_contratado DESC;

COMMIT;