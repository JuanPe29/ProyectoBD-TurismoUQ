-- =====================================================================
-- TurismoUQ - Script 00: Usuario del proyecto (base limpia)
-- Ejecutar conectado como SYSTEM en la PDB (XEPDB1 en Oracle XE 21c):
--   sqlplus system/<clave>@localhost:1521/XEPDB1 @00_CrearUsuario.sql
-- Borra el usuario y el tablespace del historico si ya existian, y los
-- vuelve a crear. Los scripts 01 a 07 se ejecutan conectados como
-- TURISMOUQ, en orden.
-- =====================================================================

-- 1. Borrar el usuario anterior (ORA-01918 = el usuario no existe)
BEGIN
    EXECUTE IMMEDIATE 'DROP USER turismouq CASCADE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -1918 THEN
            RAISE;
        END IF;
END;
/

-- 2. Borrar el tablespace del historico (ORA-00959 = no existe)
BEGIN
    EXECUTE IMMEDIATE
        'DROP TABLESPACE ts_historico_reservas INCLUDING CONTENTS AND DATAFILES';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -959 THEN
            RAISE;
        END IF;
END;
/

-- 3. Crear el usuario dueno del esquema
CREATE USER turismouq IDENTIFIED BY turismouq
    DEFAULT TABLESPACE users
    QUOTA UNLIMITED ON users;

-- 4. Privilegios necesarios para las Entregas 1 y 2
--    (CREATE TABLESPACE, UNLIMITED TABLESPACE y CREATE JOB son para el
--    script 06: tablespace del historico y refresco programado de la vista)
GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE VIEW,
      CREATE MATERIALIZED VIEW,
      CREATE PROCEDURE,
      CREATE TRIGGER,
      CREATE SEQUENCE,
      CREATE TABLESPACE,
      CREATE JOB,
      UNLIMITED TABLESPACE
TO turismouq;
