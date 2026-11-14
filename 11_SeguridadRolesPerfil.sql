-- Script 11: seguridad - roles, perfil y usuarios
-- (ejecutar como SYSTEM en XEPDB1, con F5)
--
-- Crear roles, perfiles y usuarios son privilegios de sistema que el
-- esquema TURISMOUQ no tiene (ni debe tener), por eso este script lo corre
-- SYSTEM. Los permisos sobre las tablas y vistas los da el dueno de los
-- objetos (TURISMOUQ) en el script 12.
--
--   Rol                     Usuario de prueba  Quien es
--   rol_recepcion           u_recepcion        Recepcionista: atiende clientes, reservas y pagos
--   rol_admin_alojamiento   encargado1         Encargado del alojamiento 1 (USUARIO_SISTEMA)
--   rol_gerente             u_gerente          Gerencia: reportes y analisis, solo lectura
--   rol_auditor             u_auditor          Auditoria: historial de cambios, solo lectura

SET SQLBLANKLINES ON
SET LINESIZE 200
SET PAGESIZE 100


-- 0. Limpieza (permite volver a ejecutar el script)
BEGIN
    FOR u IN (SELECT username
              FROM DBA_USERS
              WHERE username IN ('U_RECEPCION', 'ENCARGADO1', 'U_GERENTE', 'U_AUDITOR')) LOOP
        EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE';
    END LOOP;

    FOR r IN (SELECT role
              FROM DBA_ROLES
              WHERE role IN ('ROL_RECEPCION', 'ROL_ADMIN_ALOJAMIENTO',
                             'ROL_GERENTE', 'ROL_AUDITOR')) LOOP
        EXECUTE IMMEDIATE 'DROP ROLE ' || r.role;
    END LOOP;

    FOR p IN (SELECT DISTINCT profile
              FROM DBA_PROFILES
              WHERE profile = 'PERFIL_TURISMOUQ') LOOP
        EXECUTE IMMEDIATE 'DROP PROFILE ' || p.profile || ' CASCADE';
    END LOOP;
END;
/


-- 1. Perfil con limites de sesion
--    RESOURCE_LIMIT = TRUE hace que Oracle aplique los limites de recursos
--    (SESSIONS_PER_USER, IDLE_TIME, CONNECT_TIME, CPU_PER_CALL).
ALTER SYSTEM SET RESOURCE_LIMIT = TRUE;

--   SESSIONS_PER_USER      maximo 2 sesiones abiertas a la vez por usuario
--   IDLE_TIME              minutos sin actividad antes de cerrar la sesion
--   CONNECT_TIME           minutos maximos de una sesion (una jornada de 8 h)
--   CPU_PER_CALL           centesimas de segundo de CPU por llamada (60 s)
--   FAILED_LOGIN_ATTEMPTS  intentos fallidos antes de bloquear la cuenta
--   PASSWORD_LOCK_TIME     dias que la cuenta queda bloqueada (1/24 = 1 hora)
--   PASSWORD_LIFE_TIME     dias de vigencia de la clave
CREATE PROFILE perfil_turismouq LIMIT
    SESSIONS_PER_USER     2
    IDLE_TIME             15
    CONNECT_TIME          480
    CPU_PER_CALL          6000
    FAILED_LOGIN_ATTEMPTS 3
    PASSWORD_LOCK_TIME    1/24
    PASSWORD_LIFE_TIME    90;


-- 2. Roles (cada uno incluye CREATE SESSION para poder conectarse)
CREATE ROLE rol_recepcion;
CREATE ROLE rol_admin_alojamiento;
CREATE ROLE rol_gerente;
CREATE ROLE rol_auditor;

GRANT CREATE SESSION TO rol_recepcion;
GRANT CREATE SESSION TO rol_admin_alojamiento;
GRANT CREATE SESSION TO rol_gerente;
GRANT CREATE SESSION TO rol_auditor;


-- 3. Usuarios de prueba con el perfil y su rol
--    encargado1 coincide con USUARIO_SISTEMA.nombre_usuario = 'encargado1':
--    las vistas del script 12 usan ese nombre para saber cual es su alojamiento.
CREATE USER u_recepcion IDENTIFIED BY "Recepcion2026" PROFILE perfil_turismouq;
CREATE USER encargado1  IDENTIFIED BY "Encargado2026" PROFILE perfil_turismouq;
CREATE USER u_gerente   IDENTIFIED BY "Gerente2026"   PROFILE perfil_turismouq;
CREATE USER u_auditor   IDENTIFIED BY "Auditor2026"   PROFILE perfil_turismouq;

GRANT rol_recepcion         TO u_recepcion;
GRANT rol_admin_alojamiento TO encargado1;
GRANT rol_gerente           TO u_gerente;
GRANT rol_auditor           TO u_auditor;


-- 4. Verificacion
SELECT role
FROM DBA_ROLES
WHERE role LIKE 'ROL\_%' ESCAPE '\'
ORDER BY role;

SELECT u.username, u.profile, u.account_status, rp.granted_role
FROM DBA_USERS u
JOIN DBA_ROLE_PRIVS rp
    ON rp.grantee = u.username
WHERE u.profile = 'PERFIL_TURISMOUQ'
ORDER BY u.username;

SELECT resource_name, resource_type, limit
FROM DBA_PROFILES
WHERE profile = 'PERFIL_TURISMOUQ'
  AND limit <> 'DEFAULT'
ORDER BY resource_type, resource_name;
