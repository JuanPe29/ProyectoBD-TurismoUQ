-- Municipios

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (1, 'Armenia');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (2, 'Buenavista');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (3, 'Calarca');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (4, 'Circasia');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (5, 'Cordoba');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (6, 'Filandia');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (7, 'Genova');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (8, 'La Tebaida');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (9, 'Montenegro');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (10, 'Pijao');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (11, 'Quimbaya');

INSERT INTO MUNICIPIO (id_municipio, nombre)
VALUES (12, 'Salento');


-- Tipos de alojamiento

INSERT INTO TIPO_ALOJAMIENTO
(id_tipo_alojamiento, nombre, descripcion)
VALUES
(1, 'Finca cafetera',
 'Alojamiento rural relacionado con la cultura cafetera');

INSERT INTO TIPO_ALOJAMIENTO
(id_tipo_alojamiento, nombre, descripcion)
VALUES
(2, 'Hotel',
 'Establecimiento de hospedaje');

INSERT INTO TIPO_ALOJAMIENTO
(id_tipo_alojamiento, nombre, descripcion)
VALUES
(3, 'Glamping',
 'Alojamiento turistico en contacto con la naturaleza');

INSERT INTO TIPO_ALOJAMIENTO
(id_tipo_alojamiento, nombre, descripcion)
VALUES
(4, 'Hostal',
 'Alojamiento turistico de menor capacidad');


-- Alojamientos

DECLARE
    v_municipio NUMBER;
    v_tipo NUMBER;
BEGIN

    FOR i IN 1..60 LOOP

        IF i <= 12 THEN
            v_municipio := 1;

        ELSIF i <= 21 THEN
            v_municipio := 3;

        ELSIF i <= 28 THEN
            v_municipio := 12;

        ELSIF i <= 34 THEN
            v_municipio := 9;

        ELSIF i <= 39 THEN
            v_municipio := 6;

        ELSIF i <= 44 THEN
            v_municipio := 11;

        ELSIF i <= 48 THEN
            v_municipio := 8;

        ELSIF i <= 51 THEN
            v_municipio := 4;

        ELSIF i <= 54 THEN
            v_municipio := 2;

        ELSIF i <= 56 THEN
            v_municipio := 5;

        ELSIF i <= 58 THEN
            v_municipio := 7;

        ELSE
            v_municipio := 10;

        END IF;

        v_tipo := MOD(i - 1, 4) + 1;

        INSERT INTO ALOJAMIENTO (
            id_alojamiento,
            id_municipio,
            id_tipo_alojamiento,
            nombre_comercial,
            direccion,
            estrellas,
            telefono,
            correo
        )
        VALUES (
            i,
            v_municipio,
            v_tipo,
            'Alojamiento Turismo ' || i,
            'Direccion ' || i,
            MOD(i - 1, 5) + 1,
            '310' || LPAD(i, 7, '0'),
            'alojamiento' || i || '@turismouq.com'
        );

    END LOOP;

END;
/


-- Habitaciones

DECLARE
    v_id NUMBER := 1;
    v_cantidad NUMBER;
    v_tipo VARCHAR2(50);
BEGIN

    FOR a IN 1..60 LOOP

        IF a = 1 THEN
            v_cantidad := 35;

        ELSIF a = 2 THEN
            v_cantidad := 32;

        ELSIF a = 3 THEN
            v_cantidad := 30;

        ELSIF a = 4 THEN
            v_cantidad := 28;

        ELSIF a = 5 THEN
            v_cantidad := 25;

        ELSIF a <= 35 THEN
            v_cantidad := 5;

        ELSE
            v_cantidad := 4;

        END IF;

        FOR h IN 1..v_cantidad LOOP

            CASE MOD(h, 4)

                WHEN 0 THEN
                    v_tipo := 'Suite';

                WHEN 1 THEN
                    v_tipo := 'Sencilla';

                WHEN 2 THEN
                    v_tipo := 'Doble';

                ELSE
                    v_tipo := 'Cabana';

            END CASE;

            INSERT INTO HABITACION (
                id_habitacion,
                id_alojamiento,
                numero,
                capacidad_maxima,
                tipo,
                descripcion
            )
            VALUES (
                v_id,
                a,
                TO_CHAR(h),
                MOD(h - 1, 5) + 1,
                v_tipo,
                'Habitacion ' || h || ' del alojamiento ' || a
            );

            v_id := v_id + 1;

        END LOOP;

    END LOOP;

END;
/


-- Temporadas

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(1, 'Baja 2024', 2024,
 DATE '2024-01-01', DATE '2024-04-30');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(2, 'Media 2024', 2024,
 DATE '2024-05-01', DATE '2024-08-31');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(3, 'Alta 2024', 2024,
 DATE '2024-09-01', DATE '2024-12-31');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(4, 'Baja 2025', 2025,
 DATE '2025-01-01', DATE '2025-04-30');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(5, 'Media 2025', 2025,
 DATE '2025-05-01', DATE '2025-08-31');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(6, 'Alta 2025', 2025,
 DATE '2025-09-01', DATE '2025-12-31');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(7, 'Baja 2026', 2026,
 DATE '2026-01-01', DATE '2026-04-30');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(8, 'Media 2026', 2026,
 DATE '2026-05-01', DATE '2026-08-31');

INSERT INTO TEMPORADA
(id_temporada, nombre, anio, fecha_inicio, fecha_fin)
VALUES
(9, 'Alta 2026', 2026,
 DATE '2026-09-01', DATE '2026-12-31');


-- Tarifas

DECLARE
    v_precio NUMBER;
BEGIN

    FOR h IN 1..400 LOOP

        FOR t IN 1..9 LOOP

            v_precio :=
                70000 + MOD(h * 1733, 180000);

            IF MOD(t, 3) = 2 THEN

                v_precio := v_precio * 1.20;

            ELSIF MOD(t, 3) = 0 THEN

                v_precio := v_precio * 1.45;

            END IF;

            INSERT INTO TARIFA (
                id_tarifa,
                id_habitacion,
                id_temporada,
                precio_noche
            )
            VALUES (
                ((h - 1) * 9) + t,
                h,
                t,
                ROUND(v_precio, -3)
            );

        END LOOP;

    END LOOP;

END;
/


-- Clientes

DECLARE
    v_ciudad VARCHAR2(100);
BEGIN

    FOR i IN 1..3000 LOOP

        CASE MOD(i, 10)

            WHEN 0 THEN
                v_ciudad := 'Bogota';

            WHEN 1 THEN
                v_ciudad := 'Medellin';

            WHEN 2 THEN
                v_ciudad := 'Cali';

            WHEN 3 THEN
                v_ciudad := 'Pereira';

            WHEN 4 THEN
                v_ciudad := 'Manizales';

            WHEN 5 THEN
                v_ciudad := 'Barranquilla';

            WHEN 6 THEN
                v_ciudad := 'Cartagena';

            WHEN 7 THEN
                v_ciudad := 'Ibague';

            WHEN 8 THEN
                v_ciudad := 'Armenia';

            ELSE
                v_ciudad := 'Bucaramanga';

        END CASE;

        INSERT INTO CLIENTE (
            id_cliente,
            nombre,
            documento,
            correo,
            telefono,
            ciudad_origen
        )
        VALUES (
            i,
            'Cliente ' || i,
            'DOC' || LPAD(i, 7, '0'),
            'cliente' || i || '@correo.com',
            '300' || LPAD(i, 7, '0'),
            v_ciudad
        );

    END LOOP;

END;
/


-- Reservas

DECLARE
    v_fecha DATE;
    v_dias NUMBER;
    v_estado VARCHAR2(20);
BEGIN

    FOR i IN 1..25000 LOOP

        IF MOD(i, 10) < 4 THEN

            v_fecha :=
                DATE '2024-11-01'
                + MOD(i * 13, 790);

        ELSE

            v_fecha :=
                DATE '2024-01-01'
                + MOD(i * 17, 1050);

        END IF;

        IF v_fecha > DATE '2026-12-25' THEN

            v_fecha :=
                DATE '2026-12-01'
                + MOD(i, 20);

        END IF;

        v_dias := MOD(i, 5) + 1;

        CASE MOD(i, 10)

            WHEN 0 THEN
                v_estado := 'cancelada';

            WHEN 1 THEN
                v_estado := 'pendiente';

            WHEN 2 THEN
                v_estado := 'confirmada';

            WHEN 3 THEN
                v_estado := 'confirmada';

            ELSE
                v_estado := 'completada';

        END CASE;

        INSERT INTO RESERVA (
            id_reserva,
            id_cliente,
            fecha_reserva,
            fecha_checkin,
            fecha_checkout,
            estado
        )
        VALUES (
            i,
            MOD(i * 7, 3000) + 1,
            v_fecha - (MOD(i, 40) + 1),
            v_fecha,
            v_fecha + v_dias,
            v_estado
        );

    END LOOP;

END;
/


-- Reserva Habitacion

DECLARE
    v_habitacion   NUMBER;
    v_alojamiento  NUMBER;
    v_fecha_in     DATE;
    v_fecha_out    DATE;
    v_cantidad_hab NUMBER;
    v_id           NUMBER := 1;
BEGIN

    FOR i IN 1..25000 LOOP

        IF MOD(i, 10) < 7 THEN

            v_alojamiento :=
                MOD(i, 10) + 1;

        ELSE

            v_alojamiento :=
                MOD(i * 7, 50) + 11;

        END IF;

        SELECT MIN(id_habitacion),
               COUNT(*)
        INTO v_habitacion,
             v_cantidad_hab
        FROM HABITACION
        WHERE id_alojamiento = v_alojamiento;

        SELECT fecha_checkin,
               fecha_checkout
        INTO v_fecha_in,
             v_fecha_out
        FROM RESERVA
        WHERE id_reserva = i;

        v_habitacion :=
            v_habitacion
            + MOD(i, v_cantidad_hab);

        INSERT INTO RESERVA_HABITACION (
            id_reserva_habitacion,
            id_reserva,
            id_habitacion,
            fecha_entrada,
            fecha_salida
        )
        VALUES (
            v_id,
            i,
            v_habitacion,
            v_fecha_in,
            v_fecha_out
        );

        v_id := v_id + 1;


        IF MOD(i, 10) = 0 THEN

            SELECT MIN(id_habitacion),
                   COUNT(*)
            INTO v_habitacion,
                 v_cantidad_hab
            FROM HABITACION
            WHERE id_alojamiento = v_alojamiento;

            v_habitacion :=
                v_habitacion
                + MOD(i + 1, v_cantidad_hab);

            INSERT INTO RESERVA_HABITACION (
                id_reserva_habitacion,
                id_reserva,
                id_habitacion,
                fecha_entrada,
                fecha_salida
            )
            VALUES (
                v_id,
                i,
                v_habitacion,
                v_fecha_in,
                v_fecha_out
            );

            v_id := v_id + 1;

        END IF;

    END LOOP;

END;
/


-- Pagos

DECLARE
    v_id NUMBER := 1;
    v_estado VARCHAR2(20);
    v_metodo VARCHAR2(30);
    v_fecha DATE;
BEGIN

    FOR i IN 1..25000 LOOP

        CASE MOD(i, 5)

            WHEN 0 THEN
                v_metodo := 'PSE';

            WHEN 1 THEN
                v_metodo := 'tarjeta_credito';

            WHEN 2 THEN
                v_metodo := 'tarjeta_debito';

            WHEN 3 THEN
                v_metodo := 'transferencia';

            ELSE
                v_metodo := 'efectivo';

        END CASE;

        IF MOD(i, 10) = 0 THEN

            v_estado := 'fallido';

        ELSIF MOD(i, 11) = 0 THEN

            v_estado := 'pendiente';

        ELSIF MOD(i, 17) = 0 THEN

            v_estado := 'reembolsado';

        ELSE

            v_estado := 'exitoso';

        END IF;

        SELECT fecha_reserva
        INTO v_fecha
        FROM RESERVA
        WHERE id_reserva = i;

        INSERT INTO PAGO (
            id_pago,
            id_reserva,
            fecha_pago,
            monto,
            metodo,
            estado
        )
        VALUES (
            v_id,
            i,
            v_fecha,
            100000 + MOD(i * 7919, 900000),
            v_metodo,
            v_estado
        );

        v_id := v_id + 1;


        IF MOD(i, 10) = 0 THEN

            INSERT INTO PAGO (
                id_pago,
                id_reserva,
                fecha_pago,
                monto,
                metodo,
                estado
            )
            VALUES (
                v_id,
                i,
                v_fecha + 2,
                50000 + MOD(i * 3571, 300000),
                'transferencia',
                'exitoso'
            );

            v_id := v_id + 1;

        END IF;

    END LOOP;

END;
/


-- Servicios

DECLARE
    v_id NUMBER := 1;
BEGIN

    -- 4 servicios para los primeros 5 alojamientos

    FOR a IN 1..5 LOOP

        INSERT INTO SERVICIO
        VALUES (
            v_id,
            a,
            'Desayuno ' || a,
            'Servicio de desayuno',
            25000
        );

        v_id := v_id + 1;


        INSERT INTO SERVICIO
        VALUES (
            v_id,
            a,
            'Tour cafetero ' || a,
            'Tour por la zona cafetera',
            65000
        );

        v_id := v_id + 1;


        INSERT INTO SERVICIO
        VALUES (
            v_id,
            a,
            'Transporte ' || a,
            'Servicio de transporte',
            45000
        );

        v_id := v_id + 1;


        INSERT INTO SERVICIO
        VALUES (
            v_id,
            a,
            'Cena ' || a,
            'Servicio de cena',
            40000
        );

        v_id := v_id + 1;

    END LOOP;


    -- 2 servicios para los alojamientos 6 al 10

    FOR a IN 6..10 LOOP

        INSERT INTO SERVICIO
        VALUES (
            v_id,
            a,
            'Desayuno ' || a,
            'Servicio de desayuno',
            22000
        );

        v_id := v_id + 1;


        INSERT INTO SERVICIO
        VALUES (
            v_id,
            a,
            'Tour guiado ' || a,
            'Tour turistico',
            55000
        );

        v_id := v_id + 1;

    END LOOP;

END;
/


-- Reserva Servicio

DECLARE
    v_id NUMBER := 1;
    v_lineas NUMBER := 0;
BEGIN

    FOR r IN (

        SELECT rh.id_reserva,
               h.id_alojamiento

        FROM RESERVA_HABITACION rh

        JOIN HABITACION h
            ON h.id_habitacion =
               rh.id_habitacion

        WHERE h.id_alojamiento BETWEEN 1 AND 10

        GROUP BY
            rh.id_reserva,
            h.id_alojamiento

        ORDER BY
            rh.id_reserva

    ) LOOP


        FOR s IN (

            SELECT id_servicio

            FROM SERVICIO

            WHERE id_alojamiento =
                  r.id_alojamiento

            ORDER BY id_servicio

        ) LOOP

            EXIT WHEN v_lineas >= 40000;

            INSERT INTO RESERVA_SERVICIO (
                id_reserva_servicio,
                id_reserva,
                id_servicio,
                cantidad
            )
            VALUES (
                v_id,
                r.id_reserva,
                s.id_servicio,
                MOD(v_id, 4) + 1
            );

            v_id := v_id + 1;

            v_lineas :=
                v_lineas + 1;

        END LOOP;

        EXIT WHEN v_lineas >= 40000;

    END LOOP;

END;
/


-- Resenas

DECLARE
    v_id NUMBER := 1;
BEGIN

    FOR r IN (

        SELECT id_reserva,
               fecha_checkout

        FROM RESERVA

        WHERE estado = 'completada'
          AND MOD(id_reserva, 2) = 0

        ORDER BY id_reserva

    ) LOOP

        INSERT INTO RESENA (
            id_resena,
            id_reserva,
            calificacion,
            comentario,
            fecha_resena
        )
        VALUES (
            v_id,
            r.id_reserva,
            MOD(r.id_reserva, 5) + 1,
            'Resena de la estadia '
                || r.id_reserva,
            r.fecha_checkout + 1
        );

        v_id := v_id + 1;

    END LOOP;

END;
/


-- Usuarios Sistema

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(1, NULL, 'admin1', 'hash_admin1',
 'administrador', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(2, NULL, 'admin2', 'hash_admin2',
 'administrador', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(3, 1, 'encargado1', 'hash_enc1',
 'encargado', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(4, 2, 'encargado2', 'hash_enc2',
 'encargado', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(5, 3, 'encargado3', 'hash_enc3',
 'encargado', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(6, 4, 'encargado4', 'hash_enc4',
 'encargado', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(7, 5, 'encargado5', 'hash_enc5',
 'encargado', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(8, 6, 'encargado6', 'hash_enc6',
 'encargado', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(9, 7, 'encargado7', 'hash_enc7',
 'encargado', 'activo');

INSERT INTO USUARIO_SISTEMA
(id_usuario, id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES
(10, 8, 'encargado8', 'hash_enc8',
 'encargado', 'activo');


COMMIT;

SELECT 'MUNICIPIO' tabla, COUNT(*) cantidad FROM MUNICIPIO
UNION ALL
SELECT 'TIPO_ALOJAMIENTO', COUNT(*) FROM TIPO_ALOJAMIENTO
UNION ALL
SELECT 'ALOJAMIENTO', COUNT(*) FROM ALOJAMIENTO
UNION ALL
SELECT 'HABITACION', COUNT(*) FROM HABITACION
UNION ALL
SELECT 'TEMPORADA', COUNT(*) FROM TEMPORADA
UNION ALL
SELECT 'TARIFA', COUNT(*) FROM TARIFA
UNION ALL
SELECT 'CLIENTE', COUNT(*) FROM CLIENTE
UNION ALL
SELECT 'RESERVA', COUNT(*) FROM RESERVA
UNION ALL
SELECT 'RESERVA_HABITACION', COUNT(*) FROM RESERVA_HABITACION
UNION ALL
SELECT 'PAGO', COUNT(*) FROM PAGO
UNION ALL
SELECT 'SERVICIO', COUNT(*) FROM SERVICIO
UNION ALL
SELECT 'RESERVA_SERVICIO', COUNT(*) FROM RESERVA_SERVICIO
UNION ALL
SELECT 'RESENA', COUNT(*) FROM RESENA
UNION ALL
SELECT 'USUARIO_SISTEMA', COUNT(*) FROM USUARIO_SISTEMA;