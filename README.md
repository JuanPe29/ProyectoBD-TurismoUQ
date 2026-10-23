# TurismoUQ – Proyecto integrador Bases de Datos II

Base de datos de una plataforma de reservas turísticas del Quindío (Oracle XE 21c).

## Orden de ejecución

| # | Script | Conectado como |
|---|---|---|
| 00 | `00_CrearUsuario.sql`: crea el usuario TURISMOUQ (base limpia) | SYSTEM en XEPDB1 |
| 01 | `01_TablasRestricciones.sql`: tablas y restricciones | TURISMOUQ |
| 02 | `02_CargaDatos.sql`: carga de datos (DBMS_RANDOM, semilla fija) | TURISMOUQ |
| 03 | `03_ConsultasAnalisis.sql`: 7 consultas de análisis | TURISMOUQ |
| 04 | `04_PaqueteTurismoUQ.sql`: paquete con función, procedimiento y cursor | TURISMOUQ |
| 05 | `05_Disparadores.sql`: auditoría de TARIFA y control de solapes | TURISMOUQ |
| 06 | `06_TablespaceVistaMaterializada.sql`: tablespace histórico y vista materializada | TURISMOUQ |
| 07 | `07_PruebasEntrega2.sql`: pruebas de la Entrega 2 | TURISMOUQ |

En SQL Developer, ejecutar cada script completo con **F5** (Ejecutar script) y activar la salida de DBMS_OUTPUT.

## Documentación

- `Documentacion/Modelo Datos TurismoUQ.md`: modelo, reglas de negocio y decisiones de diseño (Entrega 1, corregida).
- `Documentacion/Entrega 2 - Capa PLSQL.md`: explicación y evidencia de la Entrega 2.
- `Documentacion/Diagrama ER TurismoUQ.drawio`: diagrama entidad relación (abrir en draw.io).
