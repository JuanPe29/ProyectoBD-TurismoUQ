-- Script 00: crea el usuario del proyecto (ejecutar como SYSTEM en XEPDB1)

-- Borra el usuario si ya existe
BEGIN
    EXECUTE IMMEDIATE 'DROP USER turismouq CASCADE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -1918 THEN
            RAISE;
        END IF;
END;
/

-- Borra el tablespace del historico si ya existe
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

-- Usuario y privilegios
CREATE USER turismouq IDENTIFIED BY turismouq
    DEFAULT TABLESPACE users
    QUOTA UNLIMITED ON users;

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
