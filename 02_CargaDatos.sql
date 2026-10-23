-- Script 02: carga de datos con DBMS_RANDOM (semilla fija, datos reproducibles)
-- Fecha de corte de los datos: 22/10/2026

SET SERVEROUTPUT ON
SET SQLBLANKLINES ON


-- 1. Municipios
INSERT INTO MUNICIPIO (nombre) VALUES ('Armenia');
INSERT INTO MUNICIPIO (nombre) VALUES ('Buenavista');
INSERT INTO MUNICIPIO (nombre) VALUES ('Calarca');
INSERT INTO MUNICIPIO (nombre) VALUES ('Circasia');
INSERT INTO MUNICIPIO (nombre) VALUES ('Cordoba');
INSERT INTO MUNICIPIO (nombre) VALUES ('Filandia');
INSERT INTO MUNICIPIO (nombre) VALUES ('Genova');
INSERT INTO MUNICIPIO (nombre) VALUES ('La Tebaida');
INSERT INTO MUNICIPIO (nombre) VALUES ('Montenegro');
INSERT INTO MUNICIPIO (nombre) VALUES ('Pijao');
INSERT INTO MUNICIPIO (nombre) VALUES ('Quimbaya');
INSERT INTO MUNICIPIO (nombre) VALUES ('Salento');


-- 2. Tipos de alojamiento
INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Finca cafetera', 'Alojamiento rural relacionado con la cultura cafetera');

INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Hotel', 'Establecimiento de hospedaje urbano con varias habitaciones');

INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Glamping', 'Alojamiento turistico en contacto con la naturaleza');

INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Hostal', 'Alojamiento economico de menor capacidad');


-- 3. Temporadas 2024-2026 (cubren todos los dias sin solaparse)
-- 2024
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Inicio de anio 2024',   'alta',  2024, DATE '2024-01-01', DATE '2024-01-12');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Enero-Marzo 2024',      'baja',  2024, DATE '2024-01-13', DATE '2024-03-22');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Semana Santa 2024',     'alta',  2024, DATE '2024-03-23', DATE '2024-03-31');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Abril-Junio 2024',     'media', 2024, DATE '2024-04-01', DATE '2024-06-13');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Mitad de anio 2024',    'alta',  2024, DATE '2024-06-14', DATE '2024-07-20');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Julio-Septiembre 2024', 'baja',  2024, DATE '2024-07-21', DATE '2024-09-30');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Octubre 2024',         'media', 2024, DATE '2024-10-01', DATE '2024-10-11');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Puente festivo Octubre 2024', 'alta', 2024, DATE '2024-10-12', DATE '2024-10-14');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Octubre-Noviembre 2024','baja',  2024, DATE '2024-10-15', DATE '2024-11-30');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Diciembre 2024',       'media', 2024, DATE '2024-12-01', DATE '2024-12-15');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Fin de anio 2024',      'alta',  2024, DATE '2024-12-16', DATE '2024-12-31');

-- 2025
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Inicio de anio 2025',   'alta',  2025, DATE '2025-01-01', DATE '2025-01-12');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Enero-Abril 2025',      'baja',  2025, DATE '2025-01-13', DATE '2025-04-11');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Semana Santa 2025',     'alta',  2025, DATE '2025-04-12', DATE '2025-04-20');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Abril-Junio 2025',     'media', 2025, DATE '2025-04-21', DATE '2025-06-13');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Mitad de anio 2025',    'alta',  2025, DATE '2025-06-14', DATE '2025-07-20');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Julio-Septiembre 2025', 'baja',  2025, DATE '2025-07-21', DATE '2025-09-30');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Octubre 2025',         'media', 2025, DATE '2025-10-01', DATE '2025-10-10');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Puente festivo Octubre 2025', 'alta', 2025, DATE '2025-10-11', DATE '2025-10-13');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Octubre-Noviembre 2025','baja',  2025, DATE '2025-10-14', DATE '2025-11-30');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Diciembre 2025',       'media', 2025, DATE '2025-12-01', DATE '2025-12-15');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Fin de anio 2025',      'alta',  2025, DATE '2025-12-16', DATE '2025-12-31');

-- 2026
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Inicio de anio 2026',   'alta',  2026, DATE '2026-01-01', DATE '2026-01-12');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Enero-Marzo 2026',      'baja',  2026, DATE '2026-01-13', DATE '2026-03-27');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Semana Santa 2026',     'alta',  2026, DATE '2026-03-28', DATE '2026-04-05');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Abril-Junio 2026',     'media', 2026, DATE '2026-04-06', DATE '2026-06-13');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Mitad de anio 2026',    'alta',  2026, DATE '2026-06-14', DATE '2026-07-20');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Julio-Septiembre 2026', 'baja',  2026, DATE '2026-07-21', DATE '2026-09-30');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Octubre 2026',         'media', 2026, DATE '2026-10-01', DATE '2026-10-09');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Puente festivo Octubre 2026', 'alta', 2026, DATE '2026-10-10', DATE '2026-10-12');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Baja Octubre-Noviembre 2026','baja',  2026, DATE '2026-10-13', DATE '2026-11-30');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Media Diciembre 2026',       'media', 2026, DATE '2026-12-01', DATE '2026-12-15');
INSERT INTO TEMPORADA (nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES ('Alta Fin de anio 2026',      'alta',  2026, DATE '2026-12-16', DATE '2026-12-31');


-- 4. Alojamientos (60, repartidos de forma desigual)
DECLARE
    TYPE t_numeros IS VARRAY(12) OF NUMBER;
    TYPE t_textos  IS VARRAY(60) OF VARCHAR2(40);

    -- Alojamientos por municipio
    v_cantidad t_numeros := t_numeros(12, 2, 7, 3, 2, 6, 2, 4, 6, 1, 5, 10);

    v_nombres t_textos := t_textos(
        'El Mirador', 'La Esperanza', 'Los Guaduales', 'El Cafetal', 'La Palma',
        'Bosque de Niebla', 'Las Heliconias', 'El Arriero', 'La Montana', 'Valle de Cocora',
        'Las Acacias', 'El Bambu', 'Santa Barbara', 'El Recreo', 'La Cabana',
        'San Alberto', 'El Ocaso', 'La Floresta', 'Villa Maria', 'El Eden',
        'Los Naranjos', 'La Primavera', 'El Balcon', 'La Cascada', 'El Yarumo',
        'Los Colibries', 'La Herradura', 'El Paraiso', 'La Pradera', 'El Roble',
        'Altos del Rio', 'La Granja', 'El Descanso', 'La Ceiba', 'Las Orquideas',
        'El Refugio', 'Bella Vista', 'La Loma', 'El Mortino', 'La Aurora',
        'Las Brisas', 'El Portal', 'La Fonda', 'El Retiro', 'San Rafael',
        'La Quinta', 'El Jardin', 'Los Alpes', 'La Rivera', 'El Tucan',
        'Monte Verde', 'La Colina', 'El Encanto', 'La Sierra', 'Los Andes',
        'El Guadual', 'La Ventana', 'El Sendero', 'Puerto Espejo', 'La Estrella');

    v_id_alojamiento NUMBER := 0;
    v_tipo           NUMBER;
    v_estrellas      NUMBER;
    v_prefijo        VARCHAR2(20);
    v_direccion      VARCHAR2(250);
    v_r              NUMBER;
BEGIN
    DBMS_RANDOM.SEED(2026);

    FOR m IN 1..12 LOOP
        FOR k IN 1..v_cantidad(m) LOOP
            v_id_alojamiento := v_id_alojamiento + 1;
            v_r := DBMS_RANDOM.VALUE;

            -- Tipo de alojamiento segun el municipio
            IF m IN (1, 3) THEN
                v_tipo := CASE WHEN v_r < 0.55 THEN 2      -- Hotel
                               WHEN v_r < 0.80 THEN 4      -- Hostal
                               WHEN v_r < 0.92 THEN 1      -- Finca
                               ELSE 3 END;                 -- Glamping
            ELSE
                v_tipo := CASE WHEN v_r < 0.40 THEN 1
                               WHEN v_r < 0.65 THEN 3
                               WHEN v_r < 0.85 THEN 4
                               ELSE 2 END;
            END IF;

            CASE v_tipo
                WHEN 1 THEN v_prefijo := 'Finca ';    v_estrellas := TRUNC(DBMS_RANDOM.VALUE(2, 5));
                WHEN 2 THEN v_prefijo := 'Hotel ';    v_estrellas := TRUNC(DBMS_RANDOM.VALUE(3, 6));
                WHEN 3 THEN v_prefijo := 'Glamping '; v_estrellas := TRUNC(DBMS_RANDOM.VALUE(3, 6));
                ELSE        v_prefijo := 'Hostal ';   v_estrellas := TRUNC(DBMS_RANDOM.VALUE(1, 4));
            END CASE;

            IF v_tipo IN (2, 4) THEN
                v_direccion := 'Calle ' || TRUNC(DBMS_RANDOM.VALUE(1, 50))
                            || ' # ' || TRUNC(DBMS_RANDOM.VALUE(1, 30))
                            || '-' || TRUNC(DBMS_RANDOM.VALUE(1, 99));
            ELSE
                v_direccion := 'Vereda rural, km ' || TRUNC(DBMS_RANDOM.VALUE(1, 15));
            END IF;

            INSERT INTO ALOJAMIENTO (
                id_municipio, id_tipo_alojamiento, nombre_comercial,
                direccion, estrellas, telefono, correo
            )
            VALUES (
                m,
                v_tipo,
                v_prefijo || v_nombres(v_id_alojamiento),
                v_direccion,
                v_estrellas,
                '31' || TRUNC(DBMS_RANDOM.VALUE(10000000, 99999999)),
                'reservas' || v_id_alojamiento || '@turismouq.com'
            );
        END LOOP;
    END LOOP;
END;
/


-- 5. Habitaciones (Hotel 15-40, Hostal 5-12, Glamping 3-8, Finca 3-6)
DECLARE
    v_cantidad  NUMBER;
    v_tipo      VARCHAR2(50);
    v_capacidad NUMBER;
    v_numero    VARCHAR2(20);
    v_r         NUMBER;
BEGIN
    FOR a IN (SELECT id_alojamiento, id_tipo_alojamiento
              FROM ALOJAMIENTO
              ORDER BY id_alojamiento) LOOP

        v_cantidad := CASE a.id_tipo_alojamiento
                          WHEN 2 THEN TRUNC(DBMS_RANDOM.VALUE(15, 41))
                          WHEN 4 THEN TRUNC(DBMS_RANDOM.VALUE(5, 13))
                          WHEN 3 THEN TRUNC(DBMS_RANDOM.VALUE(3, 9))
                          ELSE        TRUNC(DBMS_RANDOM.VALUE(3, 7))
                      END;

        FOR h IN 1..v_cantidad LOOP
            v_r := DBMS_RANDOM.VALUE;

            v_tipo := CASE a.id_tipo_alojamiento
                          WHEN 2 THEN CASE WHEN v_r < 0.35 THEN 'Sencilla'
                                           WHEN v_r < 0.80 THEN 'Doble'
                                           ELSE 'Suite' END
                          WHEN 1 THEN CASE WHEN v_r < 0.50 THEN 'Doble'
                                           WHEN v_r < 0.80 THEN 'Cabana'
                                           ELSE 'Suite' END
                          WHEN 3 THEN CASE WHEN v_r < 0.60 THEN 'Cabana'
                                           ELSE 'Doble' END
                          ELSE        CASE WHEN v_r < 0.50 THEN 'Sencilla'
                                           ELSE 'Doble' END
                      END;

            v_capacidad := CASE v_tipo
                               WHEN 'Sencilla' THEN TRUNC(DBMS_RANDOM.VALUE(1, 3))
                               WHEN 'Doble'    THEN TRUNC(DBMS_RANDOM.VALUE(2, 4))
                               WHEN 'Suite'    THEN TRUNC(DBMS_RANDOM.VALUE(2, 5))
                               ELSE                 TRUNC(DBMS_RANDOM.VALUE(4, 7))
                           END;

            -- Los hoteles numeran por piso
            IF a.id_tipo_alojamiento = 2 THEN
                v_numero := TO_CHAR((TRUNC((h - 1) / 10) + 1) * 100 + MOD(h - 1, 10) + 1);
            ELSE
                v_numero := TO_CHAR(h);
            END IF;

            INSERT INTO HABITACION (
                id_alojamiento, numero, capacidad_maxima, tipo, descripcion
            )
            VALUES (
                a.id_alojamiento,
                v_numero,
                v_capacidad,
                v_tipo,
                v_tipo || ' para ' || v_capacidad || ' persona(s)'
            );
        END LOOP;
    END LOOP;
END;
/


-- 6. Tarifas: una por habitacion y temporada
DECLARE
    v_base_tipo NUMBER;
    v_alza_alta NUMBER;
    v_base      NUMBER;
BEGIN
    FOR a IN (SELECT id_alojamiento, id_tipo_alojamiento, estrellas
              FROM ALOJAMIENTO
              ORDER BY id_alojamiento) LOOP

        v_base_tipo := CASE a.id_tipo_alojamiento
                           WHEN 1 THEN 180000      -- Finca
                           WHEN 2 THEN 140000      -- Hotel
                           WHEN 3 THEN 220000      -- Glamping
                           ELSE 60000              -- Hostal
                       END;

        v_alza_alta := DBMS_RANDOM.VALUE(0.10, 0.60);

        FOR h IN (SELECT id_habitacion, tipo
                  FROM HABITACION
                  WHERE id_alojamiento = a.id_alojamiento
                  ORDER BY id_habitacion) LOOP

            v_base := v_base_tipo
                    * (0.8 + 0.1 * a.estrellas)
                    * CASE h.tipo
                          WHEN 'Sencilla' THEN 0.7
                          WHEN 'Doble'    THEN 1.0
                          WHEN 'Suite'    THEN 1.6
                          ELSE 1.4
                      END
                    * DBMS_RANDOM.VALUE(0.9, 1.1);

            INSERT INTO TARIFA (id_habitacion, id_temporada, precio_noche)
            SELECT h.id_habitacion,
                   t.id_temporada,
                   ROUND(
                       v_base
                       * CASE t.categoria
                             WHEN 'alta'  THEN 1 + v_alza_alta
                             WHEN 'media' THEN 1 + v_alza_alta * 0.45
                             ELSE 1
                         END
                       * (1 + 0.06 * (t.anio - 2024)),
                       -3)
            FROM TEMPORADA t;
        END LOOP;
    END LOOP;
END;
/


-- 7. Servicios de cada alojamiento
DECLARE
    TYPE t_textos  IS VARRAY(10) OF VARCHAR2(100);
    TYPE t_numeros IS VARRAY(10) OF NUMBER;

    v_nombre t_textos := t_textos(
        'Desayuno', 'Tour guiado del cafe', 'Transporte al aeropuerto',
        'Alquiler de bicicletas', 'Spa y masajes', 'Cabalgata',
        'Avistamiento de aves', 'Cena romantica', 'Tour Valle de Cocora',
        'Entrada Parque del Cafe');
    v_desc t_textos := t_textos(
        'Desayuno tipico servido en el alojamiento',
        'Recorrido por cultivos y proceso del cafe',
        'Traslado al aeropuerto El Eden',
        'Alquiler de bicicleta por dia',
        'Sesion de spa y masaje relajante',
        'Recorrido a caballo por la zona rural',
        'Caminata guiada para observar aves',
        'Cena para dos personas',
        'Excursion al Valle de Cocora',
        'Tiquete de entrada al Parque del Cafe');
    v_precio_min t_numeros := t_numeros(18000, 60000, 50000, 30000,  90000, 70000,  80000, 120000, 90000, 75000);
    v_precio_max t_numeros := t_numeros(35000, 90000, 80000, 45000, 150000, 100000, 120000, 180000, 130000, 95000);

    v_cantidad NUMBER;
    v_inicio   NUMBER;
    v_k        NUMBER;
BEGIN
    FOR a IN (SELECT id_alojamiento, id_tipo_alojamiento
              FROM ALOJAMIENTO
              ORDER BY id_alojamiento) LOOP

        v_cantidad := CASE a.id_tipo_alojamiento
                          WHEN 2 THEN TRUNC(DBMS_RANDOM.VALUE(3, 6))
                          WHEN 4 THEN TRUNC(DBMS_RANDOM.VALUE(1, 3))
                          ELSE        TRUNC(DBMS_RANDOM.VALUE(2, 5))
                      END;

        v_inicio := TRUNC(DBMS_RANDOM.VALUE(1, 11));

        FOR s IN 1..v_cantidad LOOP
            v_k := MOD(v_inicio + s - 2, 10) + 1;

            INSERT INTO SERVICIO (id_alojamiento, nombre, descripcion, precio)
            VALUES (
                a.id_alojamiento,
                v_nombre(v_k),
                v_desc(v_k),
                ROUND(DBMS_RANDOM.VALUE(v_precio_min(v_k), v_precio_max(v_k)), -3)
            );
        END LOOP;
    END LOOP;
END;
/


-- 8. Clientes (3.000)
DECLARE
    TYPE t_textos  IS VARRAY(20) OF VARCHAR2(50);
    TYPE t_numeros IS VARRAY(20) OF NUMBER;

    v_nombres t_textos := t_textos(
        'Juan', 'Maria', 'Carlos', 'Laura', 'Andres', 'Camila', 'Santiago',
        'Valentina', 'Felipe', 'Daniela', 'Jorge', 'Paula', 'Miguel', 'Natalia',
        'David', 'Sofia', 'Luis', 'Carolina', 'Alejandro', 'Isabella');
    v_apellidos t_textos := t_textos(
        'Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Gonzalez', 'Hernandez',
        'Ramirez', 'Gomez', 'Diaz', 'Torres', 'Vargas', 'Rojas', 'Moreno',
        'Castro', 'Ortiz', 'Jimenez', 'Rios', 'Cardona', 'Osorio', 'Giraldo');
    v_ciudades t_textos := t_textos(
        'Bogota', 'Medellin', 'Cali', 'Armenia', 'Pereira', 'Manizales',
        'Ibague', 'Barranquilla', 'Bucaramanga', 'Cartagena', 'Calarca',
        'Neiva', 'Tulua', 'Cucuta', 'Madrid', 'Ciudad de Mexico', 'Miami',
        'Buenos Aires', 'Santiago de Chile', 'Quito');
    -- Porcentaje acumulado de cada ciudad
    v_acumulado t_numeros := t_numeros(
        25, 40, 52, 59, 66, 71, 75, 78, 81, 84, 86, 88, 90, 92, 94, 95.5, 97, 98, 99, 100);

    v_nombre   VARCHAR2(50);
    v_apellido VARCHAR2(50);
    v_ciudad   VARCHAR2(50);
    v_r        NUMBER;
BEGIN
    FOR i IN 1..3000 LOOP
        v_nombre   := v_nombres(TRUNC(DBMS_RANDOM.VALUE(1, 21)));
        v_apellido := v_apellidos(TRUNC(DBMS_RANDOM.VALUE(1, 21)));

        v_r := DBMS_RANDOM.VALUE(0, 100);
        FOR c IN 1..20 LOOP
            IF v_r < v_acumulado(c) THEN
                v_ciudad := v_ciudades(c);
                EXIT;
            END IF;
        END LOOP;

        INSERT INTO CLIENTE (nombre, documento, correo, telefono, ciudad_origen)
        VALUES (
            v_nombre || ' ' || v_apellido,
            TO_CHAR(1000000000 + i * 97),
            LOWER(v_nombre || '.' || v_apellido) || i || '@correo.com',
            '3' || TRUNC(DBMS_RANDOM.VALUE(100000000, 999999999)),
            v_ciudad
        );
    END LOOP;
END;
/


-- 9. Reservas, habitaciones reservadas y servicios contratados
-- Se recorre el calendario dia por dia; v_libre guarda cuando queda libre
-- cada habitacion, asi no hay solapes. La demanda depende de la temporada,
-- el dia de la semana y la popularidad del municipio.
DECLARE
    TYPE t_numeros   IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_fechas    IS TABLE OF DATE INDEX BY PLS_INTEGER;
    TYPE t_textos    IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;

    c_inicio CONSTANT DATE   := DATE '2024-01-01';
    c_fin    CONSTANT DATE   := DATE '2026-12-31';
    c_corte  CONSTANT DATE   := DATE '2026-10-22';
    c_base   CONSTANT NUMBER := 0.036;               -- probabilidad base diaria

    v_pop_municipio t_numeros;
    v_categoria_dia t_textos;
    v_habitaciones  t_numeros;
    v_capacidades   t_numeros;
    v_servicios     t_numeros;
    v_libre         t_fechas;

    v_dia            DATE;
    v_demanda        NUMBER;
    v_popularidad    NUMBER;
    v_noches         NUMBER;
    v_checkin        DATE;
    v_checkout       DATE;
    v_entrada        DATE;
    v_fecha_reserva  DATE;
    v_fecha_cancel   DATE;
    v_limite         DATE;
    v_estado         VARCHAR2(20);
    v_id_reserva     NUMBER;
    v_extra          NUMBER;
    v_num_servicios  NUMBER;
    v_inicio_serv    NUMBER;
    v_id_servicio    NUMBER;
    v_r              NUMBER;
BEGIN
    -- Popularidad de cada municipio
    v_pop_municipio(1)  := 1.00;  -- Armenia
    v_pop_municipio(2)  := 0.60;  -- Buenavista
    v_pop_municipio(3)  := 0.80;  -- Calarca
    v_pop_municipio(4)  := 0.85;  -- Circasia
    v_pop_municipio(5)  := 0.50;  -- Cordoba
    v_pop_municipio(6)  := 1.15;  -- Filandia
    v_pop_municipio(7)  := 0.50;  -- Genova
    v_pop_municipio(8)  := 0.90;  -- La Tebaida
    v_pop_municipio(9)  := 1.25;  -- Montenegro
    v_pop_municipio(10) := 0.45;  -- Pijao
    v_pop_municipio(11) := 1.10;  -- Quimbaya
    v_pop_municipio(12) := 1.40;  -- Salento

    -- Categoria de temporada de cada dia
    FOR t IN (SELECT categoria, fecha_inicio, fecha_fin FROM TEMPORADA) LOOP
        v_dia := t.fecha_inicio;
        WHILE v_dia <= t.fecha_fin LOOP
            v_categoria_dia(v_dia - c_inicio) := t.categoria;
            v_dia := v_dia + 1;
        END LOOP;
    END LOOP;

    FOR a IN (SELECT id_alojamiento, id_municipio
              FROM ALOJAMIENTO
              ORDER BY id_alojamiento) LOOP

        SELECT id_habitacion, capacidad_maxima
        BULK COLLECT INTO v_habitaciones, v_capacidades
        FROM HABITACION
        WHERE id_alojamiento = a.id_alojamiento
        ORDER BY id_habitacion;

        SELECT id_servicio
        BULK COLLECT INTO v_servicios
        FROM SERVICIO
        WHERE id_alojamiento = a.id_alojamiento
        ORDER BY id_servicio;

        v_libre.DELETE;
        FOR k IN 1..v_habitaciones.COUNT LOOP
            v_libre(k) := c_inicio;
        END LOOP;

        v_popularidad := v_pop_municipio(a.id_municipio) * DBMS_RANDOM.VALUE(0.6, 1.4);

        v_dia := c_inicio;
        WHILE v_dia <= c_fin LOOP

            v_demanda := c_base * v_popularidad
                       * CASE v_categoria_dia(v_dia - c_inicio)
                             WHEN 'alta'  THEN 2.2
                             WHEN 'media' THEN 1.0
                             ELSE 0.55
                         END
                       * CASE WHEN TO_CHAR(v_dia, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('FRI', 'SAT')
                              THEN 1.6 ELSE 0.85 END;

            FOR k IN 1..v_habitaciones.COUNT LOOP

                IF v_libre(k) <= v_dia AND DBMS_RANDOM.VALUE < v_demanda THEN

                    -- Noches de la estadia
                    v_r := DBMS_RANDOM.VALUE;
                    v_noches := CASE WHEN v_r < 0.30 THEN 1
                                     WHEN v_r < 0.65 THEN 2
                                     WHEN v_r < 0.85 THEN 3
                                     ELSE TRUNC(DBMS_RANDOM.VALUE(4, 8)) END;

                    v_checkin  := v_dia;
                    v_checkout := v_dia + v_noches;

                    IF v_checkout <= c_fin + 1 THEN

                        -- Fecha en que se hizo la reserva
                        IF DBMS_RANDOM.VALUE < 0.8 THEN
                            v_fecha_reserva := v_checkin - TRUNC(DBMS_RANDOM.VALUE(1, 31));
                        ELSE
                            v_fecha_reserva := v_checkin - TRUNC(DBMS_RANDOM.VALUE(31, 91));
                        END IF;
                        IF v_fecha_reserva > c_corte THEN
                            v_fecha_reserva := c_corte - TRUNC(DBMS_RANDOM.VALUE(0, 15));
                        END IF;

                        -- Estado segun la fecha de corte
                        v_r := DBMS_RANDOM.VALUE;
                        IF v_checkout <= c_corte THEN
                            v_estado := CASE WHEN v_r < 0.12 THEN 'cancelada' ELSE 'completada' END;
                        ELSIF v_checkin <= c_corte THEN
                            v_estado := 'confirmada';            -- estadia en curso
                        ELSE
                            v_estado := CASE WHEN v_r < 0.10 THEN 'cancelada'
                                             WHEN v_r < 0.45 THEN 'pendiente'
                                             ELSE 'confirmada' END;
                        END IF;

                        v_fecha_cancel := NULL;
                        IF v_estado = 'cancelada' THEN
                            v_limite := LEAST(v_checkin - 1, c_corte);
                            IF v_limite <= v_fecha_reserva THEN
                                v_fecha_cancel := v_fecha_reserva;
                            ELSE
                                v_fecha_cancel := v_fecha_reserva
                                    + TRUNC(DBMS_RANDOM.VALUE(0, v_limite - v_fecha_reserva + 1));
                            END IF;
                        END IF;

                        INSERT INTO RESERVA (
                            id_cliente, fecha_reserva, fecha_checkin,
                            fecha_checkout, estado, fecha_cancelacion
                        )
                        VALUES (
                            TRUNC(3000 * POWER(DBMS_RANDOM.VALUE, 1.6)) + 1,
                            v_fecha_reserva,
                            v_checkin,
                            v_checkout,
                            v_estado,
                            v_fecha_cancel
                        )
                        RETURNING id_reserva INTO v_id_reserva;

                        INSERT INTO RESERVA_HABITACION (
                            id_reserva, id_habitacion, fecha_entrada,
                            fecha_salida, num_huespedes
                        )
                        VALUES (
                            v_id_reserva,
                            v_habitaciones(k),
                            v_checkin,
                            v_checkout,
                            TRUNC(DBMS_RANDOM.VALUE(1, v_capacidades(k) + 1))
                        );
                        v_libre(k) := v_checkout;

                        -- Reservas de grupo (1 o 2 habitaciones mas)
                        IF v_habitaciones.COUNT > 1 AND DBMS_RANDOM.VALUE < 0.12 THEN
                            v_extra := TRUNC(DBMS_RANDOM.VALUE(1, 3));

                            FOR j IN k + 1..v_habitaciones.COUNT LOOP
                                EXIT WHEN v_extra = 0;

                                IF v_libre(j) <= v_dia THEN
                                    v_entrada := v_checkin;
                                    IF v_noches > 1 AND DBMS_RANDOM.VALUE < 0.25 THEN
                                        v_entrada := v_checkin + 1;   -- llega un dia despues
                                    END IF;

                                    INSERT INTO RESERVA_HABITACION (
                                        id_reserva, id_habitacion, fecha_entrada,
                                        fecha_salida, num_huespedes
                                    )
                                    VALUES (
                                        v_id_reserva,
                                        v_habitaciones(j),
                                        v_entrada,
                                        v_checkout,
                                        TRUNC(DBMS_RANDOM.VALUE(1, v_capacidades(j) + 1))
                                    );
                                    v_libre(j) := v_checkout;
                                    v_extra := v_extra - 1;
                                END IF;
                            END LOOP;
                        END IF;

                        -- Servicios del mismo alojamiento
                        IF v_servicios.COUNT > 0 THEN
                            v_r := DBMS_RANDOM.VALUE;
                            v_num_servicios := CASE WHEN v_r < 0.12 THEN 0
                                                    WHEN v_r < 0.40 THEN 1
                                                    WHEN v_r < 0.72 THEN 2
                                                    ELSE 3 END;
                            v_num_servicios := LEAST(v_num_servicios, v_servicios.COUNT);
                            v_inicio_serv := TRUNC(DBMS_RANDOM.VALUE(1, v_servicios.COUNT + 1));

                            FOR s IN 1..v_num_servicios LOOP
                                v_id_servicio := v_servicios(MOD(v_inicio_serv + s - 2, v_servicios.COUNT) + 1);

                                INSERT INTO RESERVA_SERVICIO (id_reserva, id_servicio, cantidad)
                                VALUES (
                                    v_id_reserva,
                                    v_id_servicio,
                                    TRUNC(DBMS_RANDOM.VALUE(1, 5))
                                );
                            END LOOP;
                        END IF;

                    END IF;
                END IF;
            END LOOP;

            v_dia := v_dia + 1;
        END LOOP;
    END LOOP;
END;
/


-- 10. Pagos segun el valor de cada reserva (noches + servicios) y su estado
DECLARE
    c_corte CONSTANT DATE := DATE '2026-10-22';

    v_anticipo NUMBER;

    FUNCTION metodo(p_incluye_efectivo BOOLEAN) RETURN VARCHAR2 IS
        v_r NUMBER := DBMS_RANDOM.VALUE;
    BEGIN
        IF p_incluye_efectivo AND v_r < 0.25 THEN
            RETURN 'efectivo';
        ELSIF v_r < 0.55 THEN
            RETURN 'tarjeta_credito';
        ELSIF v_r < 0.75 THEN
            RETURN 'PSE';
        ELSIF v_r < 0.90 THEN
            RETURN 'tarjeta_debito';
        ELSE
            RETURN 'transferencia';
        END IF;
    END metodo;

    PROCEDURE registrar_pago(p_reserva NUMBER, p_fecha DATE, p_monto NUMBER,
                             p_metodo VARCHAR2, p_estado VARCHAR2) IS
    BEGIN
        INSERT INTO PAGO (id_reserva, fecha_pago, monto, metodo, estado)
        VALUES (p_reserva, p_fecha, p_monto, p_metodo, p_estado);
    END registrar_pago;
BEGIN
    FOR r IN (
        WITH valor_estadia AS (
            SELECT rh.id_reserva,
                   SUM( (LEAST(rh.fecha_salida, te.fecha_fin + 1)
                         - GREATEST(rh.fecha_entrada, te.fecha_inicio))
                        * ta.precio_noche ) AS valor
            FROM RESERVA_HABITACION rh
            JOIN TEMPORADA te
                ON te.fecha_inicio < rh.fecha_salida
               AND te.fecha_fin >= rh.fecha_entrada
            JOIN TARIFA ta
                ON ta.id_habitacion = rh.id_habitacion
               AND ta.id_temporada = te.id_temporada
            GROUP BY rh.id_reserva
        ),
        valor_servicios AS (
            SELECT rs.id_reserva,
                   SUM(rs.cantidad * s.precio) AS valor
            FROM RESERVA_SERVICIO rs
            JOIN SERVICIO s
                ON s.id_servicio = rs.id_servicio
            GROUP BY rs.id_reserva
        )
        SELECT r.id_reserva,
               r.estado,
               r.fecha_reserva,
               r.fecha_checkin,
               r.fecha_cancelacion,
               ve.valor + NVL(vs.valor, 0) AS total
        FROM RESERVA r
        JOIN valor_estadia ve
            ON ve.id_reserva = r.id_reserva
        LEFT JOIN valor_servicios vs
            ON vs.id_reserva = r.id_reserva
        ORDER BY r.id_reserva
    ) LOOP

        v_anticipo := ROUND(r.total * DBMS_RANDOM.VALUE(0.3, 0.5), -3);

        IF r.estado = 'completada' THEN
            IF DBMS_RANDOM.VALUE < 0.06 THEN
                registrar_pago(r.id_reserva, r.fecha_reserva, v_anticipo, metodo(FALSE), 'fallido');
            END IF;

            IF DBMS_RANDOM.VALUE < 0.5 THEN
                registrar_pago(r.id_reserva, r.fecha_reserva, r.total, metodo(FALSE), 'exitoso');
            ELSE
                registrar_pago(r.id_reserva, r.fecha_reserva, v_anticipo, metodo(FALSE), 'exitoso');
                registrar_pago(r.id_reserva, r.fecha_checkin, r.total - v_anticipo, metodo(TRUE), 'exitoso');
            END IF;

        ELSIF r.estado = 'confirmada' THEN
            IF DBMS_RANDOM.VALUE < 0.3 THEN
                registrar_pago(r.id_reserva, r.fecha_reserva, r.total, metodo(FALSE), 'exitoso');
            ELSE
                registrar_pago(r.id_reserva, r.fecha_reserva, v_anticipo, metodo(FALSE), 'exitoso');
                IF r.fecha_checkin <= c_corte THEN
                    registrar_pago(r.id_reserva, r.fecha_checkin, r.total - v_anticipo, metodo(TRUE), 'exitoso');
                END IF;
            END IF;

        ELSIF r.estado = 'pendiente' THEN
            IF DBMS_RANDOM.VALUE < 0.5 THEN
                registrar_pago(r.id_reserva, r.fecha_reserva, v_anticipo, 'PSE', 'pendiente');
            END IF;

        ELSIF r.estado = 'cancelada' THEN
            IF DBMS_RANDOM.VALUE < 0.7 THEN
                registrar_pago(r.id_reserva, r.fecha_reserva, v_anticipo, metodo(FALSE), 'exitoso');

                IF r.fecha_checkin - r.fecha_cancelacion > 5 THEN
                    registrar_pago(r.id_reserva, r.fecha_cancelacion, ROUND(v_anticipo * 0.8),
                                   'transferencia', 'reembolsado');
                END IF;
            END IF;
        END IF;

    END LOOP;
END;
/


-- 11. Resenas de reservas completadas
DECLARE
    TYPE t_numeros IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_textos  IS VARRAY(5) OF VARCHAR2(200);

    c_corte CONSTANT DATE := DATE '2026-10-22';

    v_calidad t_numeros;
    v_comentarios t_textos := t_textos(
        'Mala experiencia, la habitacion no correspondia a lo ofrecido',
        'Regular, el servicio puede mejorar bastante',
        'Buena estadia aunque hay detalles por mejorar',
        'Muy buena atencion y lugar muy agradable',
        'Excelente, el paisaje y la atencion superaron lo esperado');

    v_calificacion NUMBER;
BEGIN
    FOR a IN (SELECT id_alojamiento FROM ALOJAMIENTO) LOOP
        v_calidad(a.id_alojamiento) := DBMS_RANDOM.VALUE(2.6, 4.9);
    END LOOP;

    FOR r IN (
        SELECT r.id_reserva,
               r.fecha_checkout,
               MIN(h.id_alojamiento) AS id_alojamiento
        FROM RESERVA r
        JOIN RESERVA_HABITACION rh
            ON rh.id_reserva = r.id_reserva
        JOIN HABITACION h
            ON h.id_habitacion = rh.id_habitacion
        WHERE r.estado = 'completada'
        GROUP BY r.id_reserva, r.fecha_checkout
        ORDER BY r.id_reserva
    ) LOOP
        IF DBMS_RANDOM.VALUE < 0.55 THEN
            v_calificacion := ROUND(v_calidad(r.id_alojamiento) + DBMS_RANDOM.NORMAL * 0.8);
            v_calificacion := GREATEST(1, LEAST(5, v_calificacion));

            INSERT INTO RESENA (id_reserva, calificacion, comentario, fecha_resena)
            VALUES (
                r.id_reserva,
                v_calificacion,
                CASE WHEN DBMS_RANDOM.VALUE < 0.25 THEN NULL       -- comentario opcional
                     ELSE v_comentarios(v_calificacion) END,
                LEAST(r.fecha_checkout + TRUNC(DBMS_RANDOM.VALUE(0, 11)), c_corte)
            );
        END IF;
    END LOOP;
END;
/


-- 12. Usuarios: 2 administradores y 2 encargados por tipo de alojamiento
INSERT INTO USUARIO_SISTEMA (id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES (NULL, 'admin.general', 'hash_admin_general', 'administrador', 'activo');

INSERT INTO USUARIO_SISTEMA (id_alojamiento, nombre_usuario, clave, rol, estado)
VALUES (NULL, 'admin.soporte', 'hash_admin_soporte', 'administrador', 'activo');

INSERT INTO USUARIO_SISTEMA (id_alojamiento, nombre_usuario, clave, rol, estado)
SELECT id_alojamiento,
       'encargado' || id_alojamiento,
       'hash_encargado' || id_alojamiento,
       'encargado',
       'activo'
FROM (
    SELECT id_alojamiento,
           ROW_NUMBER() OVER (PARTITION BY id_tipo_alojamiento
                              ORDER BY id_alojamiento) AS fila
    FROM ALOJAMIENTO
)
WHERE fila <= 2;

COMMIT;


-- 13. Verificacion: cantidad de filas por tabla
SELECT 'MUNICIPIO' tabla, COUNT(*) cantidad FROM MUNICIPIO
UNION ALL SELECT 'TIPO_ALOJAMIENTO', COUNT(*) FROM TIPO_ALOJAMIENTO
UNION ALL SELECT 'ALOJAMIENTO', COUNT(*) FROM ALOJAMIENTO
UNION ALL SELECT 'HABITACION', COUNT(*) FROM HABITACION
UNION ALL SELECT 'TEMPORADA', COUNT(*) FROM TEMPORADA
UNION ALL SELECT 'TARIFA', COUNT(*) FROM TARIFA
UNION ALL SELECT 'CLIENTE', COUNT(*) FROM CLIENTE
UNION ALL SELECT 'RESERVA', COUNT(*) FROM RESERVA
UNION ALL SELECT 'RESERVA_HABITACION', COUNT(*) FROM RESERVA_HABITACION
UNION ALL SELECT 'PAGO', COUNT(*) FROM PAGO
UNION ALL SELECT 'SERVICIO', COUNT(*) FROM SERVICIO
UNION ALL SELECT 'RESERVA_SERVICIO', COUNT(*) FROM RESERVA_SERVICIO
UNION ALL SELECT 'RESENA', COUNT(*) FROM RESENA
UNION ALL SELECT 'USUARIO_SISTEMA', COUNT(*) FROM USUARIO_SISTEMA;

-- Verificacion de coherencia (todo debe dar 0, excepto el % de resenas)
SELECT
    (SELECT COUNT(*)
     FROM RESERVA_HABITACION a
     JOIN RESERVA_HABITACION b
         ON a.id_habitacion = b.id_habitacion
        AND a.id_reserva_habitacion < b.id_reserva_habitacion
        AND a.fecha_entrada < b.fecha_salida
        AND b.fecha_entrada < a.fecha_salida
     JOIN RESERVA ra ON ra.id_reserva = a.id_reserva
     JOIN RESERVA rb ON rb.id_reserva = b.id_reserva
     WHERE ra.estado <> 'cancelada'
       AND rb.estado <> 'cancelada') AS solapes,

    (SELECT COUNT(*)
     FROM ALOJAMIENTO a
     WHERE NOT EXISTS (SELECT 1
                       FROM HABITACION h
                       JOIN RESERVA_HABITACION rh ON rh.id_habitacion = h.id_habitacion
                       WHERE h.id_alojamiento = a.id_alojamiento)) AS alojamientos_sin_reservas,

    (SELECT COUNT(*)
     FROM (SELECT DATE '2024-01-01' + LEVEL - 1 AS dia
           FROM DUAL CONNECT BY LEVEL <= DATE '2027-01-01' - DATE '2024-01-01') d
     WHERE (SELECT COUNT(*) FROM TEMPORADA t
            WHERE d.dia BETWEEN t.fecha_inicio AND t.fecha_fin) <> 1) AS dias_sin_temporada_unica,

    (SELECT COUNT(*)
     FROM RESENA re
     JOIN RESERVA r ON r.id_reserva = re.id_reserva
     WHERE r.estado <> 'completada') AS resenas_invalidas,

    (SELECT COUNT(*)
     FROM RESERVA_SERVICIO rs
     JOIN SERVICIO s ON s.id_servicio = rs.id_servicio
     WHERE NOT EXISTS (SELECT 1
                       FROM RESERVA_HABITACION rh
                       JOIN HABITACION h ON h.id_habitacion = rh.id_habitacion
                       WHERE rh.id_reserva = rs.id_reserva
                         AND h.id_alojamiento = s.id_alojamiento)) AS servicios_otro_alojamiento,

    (SELECT COUNT(*)
     FROM RESERVA_HABITACION rh
     JOIN HABITACION h ON h.id_habitacion = rh.id_habitacion
     WHERE rh.num_huespedes > h.capacidad_maxima) AS capacidad_excedida,

    (SELECT ROUND(100 * COUNT(re.id_resena) / NULLIF(COUNT(*), 0), 1)
     FROM RESERVA r
     LEFT JOIN RESENA re ON re.id_reserva = r.id_reserva
     WHERE r.estado = 'completada') AS pct_resenas
FROM DUAL;

-- Reservas por estado
SELECT estado, COUNT(*) AS reservas
FROM RESERVA
GROUP BY estado
ORDER BY estado;
