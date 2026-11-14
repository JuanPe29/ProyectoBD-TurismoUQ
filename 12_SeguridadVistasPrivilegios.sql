-- Script 12: seguridad - vistas y privilegios de cada rol
-- (ejecutar como TURISMOUQ con F5, despues del script 11)
--
-- Principio de minimo privilegio: cada rol recibe solo lo que necesita
-- para su trabajo.
--
--   rol_recepcion          Solo VISTAS (ninguna tabla). Registra clientes y
--                          pagos, cambia el estado de las reservas y crea
--                          reservas con los procedimientos que validan las
--                          reglas de negocio.
--   rol_admin_alojamiento  Vistas filtradas por SU alojamiento (WITH CHECK
--                          OPTION): habitaciones, tarifas y servicios propios;
--                          consulta las reservas de su alojamiento.
--   rol_gerente            Solo lectura de todo lo necesario para los reportes,
--                          sin datos personales de los clientes.
--   rol_auditor            Solo lectura de la auditoria y de los movimientos
--                          (tarifas, pagos, reservas, usuarios sin clave).

SET SQLBLANKLINES ON
SET LINESIZE 200
SET PAGESIZE 100


-- =====================================================================
-- 1. RECEPCION: solo vistas
-- =====================================================================

-- Clientes: consultar, registrar y actualizar datos de contacto
CREATE OR REPLACE VIEW v_recep_clientes AS
SELECT id_cliente,
       nombre,
       documento,
       correo,
       telefono,
       ciudad_origen
FROM CLIENTE;

-- Habitaciones disponibles para ofrecer (catalogo, solo lectura)
CREATE OR REPLACE VIEW v_recep_habitaciones AS
SELECT h.id_habitacion,
       a.nombre_comercial AS alojamiento,
       m.nombre           AS municipio,
       ta.nombre          AS tipo_alojamiento,
       h.numero,
       h.tipo,
       h.capacidad_maxima,
       h.descripcion
FROM HABITACION h
JOIN ALOJAMIENTO a
    ON a.id_alojamiento = h.id_alojamiento
JOIN MUNICIPIO m
    ON m.id_municipio = a.id_municipio
JOIN TIPO_ALOJAMIENTO ta
    ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
WITH READ ONLY;

-- Reservas con cliente, habitacion y lo pagado (solo lectura)
CREATE OR REPLACE VIEW v_recep_reservas AS
SELECT r.id_reserva,
       c.id_cliente,
       c.nombre AS cliente,
       c.documento,
       a.nombre_comercial AS alojamiento,
       h.id_habitacion,
       h.numero AS habitacion,
       rh.fecha_entrada,
       rh.fecha_salida,
       rh.num_huespedes,
       r.estado,
       (SELECT NVL(SUM(p.monto), 0)
        FROM PAGO p
        WHERE p.id_reserva = r.id_reserva
          AND p.estado = 'exitoso') AS pagado
FROM RESERVA r
JOIN CLIENTE c
    ON c.id_cliente = r.id_cliente
JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva
JOIN HABITACION h
    ON h.id_habitacion = rh.id_habitacion
JOIN ALOJAMIENTO a
    ON a.id_alojamiento = h.id_alojamiento
WITH READ ONLY;

-- Estado de la reserva: check-in, check-out y cancelaciones
CREATE OR REPLACE VIEW v_recep_estado_reserva AS
SELECT id_reserva,
       id_cliente,
       fecha_checkin,
       fecha_checkout,
       estado,
       fecha_cancelacion
FROM RESERVA;

-- Pagos: consultar y registrar abonos
CREATE OR REPLACE VIEW v_recep_pagos AS
SELECT id_pago,
       id_reserva,
       fecha_pago,
       monto,
       metodo,
       estado
FROM PAGO;

GRANT SELECT, INSERT                         ON v_recep_clientes       TO rol_recepcion;
GRANT UPDATE (correo, telefono, ciudad_origen) ON v_recep_clientes     TO rol_recepcion;
GRANT SELECT                                 ON v_recep_habitaciones   TO rol_recepcion;
GRANT SELECT                                 ON v_recep_reservas       TO rol_recepcion;
GRANT SELECT                                 ON v_recep_estado_reserva TO rol_recepcion;
GRANT UPDATE (estado, fecha_cancelacion)     ON v_recep_estado_reserva TO rol_recepcion;
GRANT SELECT, INSERT                         ON v_recep_pagos          TO rol_recepcion;

-- Crear reservas: por procedimiento (valida fechas, capacidad, disponibilidad
-- y bloquea la habitacion). Corre con los permisos del dueno, asi que
-- recepcion no necesita ningun privilegio sobre las tablas.
GRANT EXECUTE ON sp_reserva_con_pago     TO rol_recepcion;
GRANT EXECUTE ON sp_crear_reserva_segura TO rol_recepcion;


-- =====================================================================
-- 2. ADMINISTRADOR DE ALOJAMIENTO: solo su alojamiento
-- =====================================================================
-- El alojamiento del usuario conectado se obtiene de USUARIO_SISTEMA:
--   nombre_usuario = usuario de la sesion, rol encargado y activo.
-- WITH CHECK OPTION impide insertar o mover filas a otro alojamiento.

CREATE OR REPLACE VIEW v_admin_habitaciones AS
SELECT h.id_habitacion,
       h.id_alojamiento,
       h.numero,
       h.capacidad_maxima,
       h.tipo,
       h.descripcion
FROM HABITACION h
WHERE h.id_alojamiento = (SELECT us.id_alojamiento
                          FROM USUARIO_SISTEMA us
                          WHERE UPPER(us.nombre_usuario) = SYS_CONTEXT('USERENV', 'SESSION_USER')
                            AND us.rol = 'encargado'
                            AND us.estado = 'activo')
WITH CHECK OPTION;

CREATE OR REPLACE VIEW v_admin_tarifas AS
SELECT ta.id_tarifa,
       ta.id_habitacion,
       ta.id_temporada,
       ta.precio_noche
FROM TARIFA ta
WHERE ta.id_habitacion IN (SELECT h.id_habitacion
                           FROM HABITACION h
                           JOIN USUARIO_SISTEMA us
                               ON us.id_alojamiento = h.id_alojamiento
                           WHERE UPPER(us.nombre_usuario) = SYS_CONTEXT('USERENV', 'SESSION_USER')
                             AND us.rol = 'encargado'
                             AND us.estado = 'activo')
WITH CHECK OPTION;

CREATE OR REPLACE VIEW v_admin_servicios AS
SELECT s.id_servicio,
       s.id_alojamiento,
       s.nombre,
       s.descripcion,
       s.precio
FROM SERVICIO s
WHERE s.id_alojamiento = (SELECT us.id_alojamiento
                          FROM USUARIO_SISTEMA us
                          WHERE UPPER(us.nombre_usuario) = SYS_CONTEXT('USERENV', 'SESSION_USER')
                            AND us.rol = 'encargado'
                            AND us.estado = 'activo')
WITH CHECK OPTION;

CREATE OR REPLACE VIEW v_admin_reservas AS
SELECT r.id_reserva,
       r.estado,
       h.id_habitacion,
       h.numero AS habitacion,
       rh.fecha_entrada,
       rh.fecha_salida,
       rh.num_huespedes
FROM RESERVA r
JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva
JOIN HABITACION h
    ON h.id_habitacion = rh.id_habitacion
WHERE h.id_alojamiento = (SELECT us.id_alojamiento
                          FROM USUARIO_SISTEMA us
                          WHERE UPPER(us.nombre_usuario) = SYS_CONTEXT('USERENV', 'SESSION_USER')
                            AND us.rol = 'encargado'
                            AND us.estado = 'activo')
WITH READ ONLY;

GRANT SELECT, INSERT, UPDATE        ON v_admin_habitaciones TO rol_admin_alojamiento;
GRANT SELECT, INSERT                ON v_admin_tarifas      TO rol_admin_alojamiento;
GRANT UPDATE (precio_noche)         ON v_admin_tarifas      TO rol_admin_alojamiento;
GRANT SELECT, INSERT, UPDATE        ON v_admin_servicios    TO rol_admin_alojamiento;
GRANT SELECT                        ON v_admin_reservas     TO rol_admin_alojamiento;
GRANT SELECT                        ON TEMPORADA            TO rol_admin_alojamiento;


-- =====================================================================
-- 3. GERENTE: solo lectura para reportes
-- =====================================================================

-- Clientes sin datos personales (documento, correo y telefono)
CREATE OR REPLACE VIEW v_gerente_clientes AS
SELECT id_cliente,
       ciudad_origen
FROM CLIENTE
WITH READ ONLY;

GRANT SELECT ON MUNICIPIO            TO rol_gerente;
GRANT SELECT ON TIPO_ALOJAMIENTO     TO rol_gerente;
GRANT SELECT ON ALOJAMIENTO          TO rol_gerente;
GRANT SELECT ON HABITACION           TO rol_gerente;
GRANT SELECT ON TEMPORADA            TO rol_gerente;
GRANT SELECT ON TARIFA               TO rol_gerente;
GRANT SELECT ON RESERVA              TO rol_gerente;
GRANT SELECT ON RESERVA_HABITACION   TO rol_gerente;
GRANT SELECT ON PAGO                 TO rol_gerente;
GRANT SELECT ON SERVICIO             TO rol_gerente;
GRANT SELECT ON RESERVA_SERVICIO     TO rol_gerente;
GRANT SELECT ON RESENA               TO rol_gerente;
GRANT SELECT ON RESERVA_HISTORICO    TO rol_gerente;
GRANT SELECT ON LIQUIDACION_MENSUAL  TO rol_gerente;
GRANT SELECT ON MV_OCUPACION_MENSUAL TO rol_gerente;
GRANT SELECT ON v_gerente_clientes   TO rol_gerente;


-- =====================================================================
-- 4. AUDITOR: solo lectura de auditoria y movimientos
-- =====================================================================

-- Usuarios internos sin la clave
CREATE OR REPLACE VIEW v_auditor_usuarios AS
SELECT id_usuario,
       id_alojamiento,
       nombre_usuario,
       rol,
       estado
FROM USUARIO_SISTEMA
WITH READ ONLY;

GRANT SELECT ON AUDITORIA_TARIFA   TO rol_auditor;
GRANT SELECT ON TARIFA             TO rol_auditor;
GRANT SELECT ON PAGO               TO rol_auditor;
GRANT SELECT ON RESERVA            TO rol_auditor;
GRANT SELECT ON RESERVA_HISTORICO  TO rol_auditor;
GRANT SELECT ON v_auditor_usuarios TO rol_auditor;


-- =====================================================================
-- 5. Verificacion
-- =====================================================================

-- Privilegios por rol y tipo de objeto
-- (la vista materializada aparece como TABLE: es la tabla que guarda sus datos)
SELECT p.grantee AS rol,
       o.object_type,
       p.table_name AS objeto,
       LISTAGG(p.privilege, ', ') WITHIN GROUP (ORDER BY p.privilege) AS privilegios
FROM USER_TAB_PRIVS_MADE p
JOIN USER_OBJECTS o
    ON o.object_name = p.table_name
   AND o.object_type IN ('TABLE', 'VIEW', 'PROCEDURE')
WHERE p.grantee LIKE 'ROL\_%' ESCAPE '\'
GROUP BY p.grantee, o.object_type, p.table_name
ORDER BY p.grantee, o.object_type, p.table_name;

-- Privilegios de columna (UPDATE limitado a ciertas columnas)
SELECT grantee AS rol, table_name AS objeto, column_name, privilege
FROM USER_COL_PRIVS_MADE
WHERE grantee LIKE 'ROL\_%' ESCAPE '\'
ORDER BY grantee, table_name, column_name;

-- Recepcion no tiene ningun privilegio sobre tablas (debe dar 0)
SELECT COUNT(*) AS privilegios_recepcion_sobre_tablas
FROM USER_TAB_PRIVS_MADE p
JOIN USER_OBJECTS o
    ON o.object_name = p.table_name
   AND o.object_type = 'TABLE'
WHERE p.grantee = 'ROL_RECEPCION';
