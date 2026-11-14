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
| 08 | `08_Transacciones.sql`: reserva + pago atómicos con SAVEPOINT y rollback parcial | TURISMOUQ |
| 09 | `09_Concurrencia.sql`: prepara el experimento de concurrencia (SELECT ... FOR UPDATE) | TURISMOUQ |
| 09a / 09b | `09a_Concurrencia_Sesion1.sql` y `09b_Concurrencia_Sesion2.sql`: pasos de cada sesión, ejecutados en orden alternando entre dos conexiones | TURISMOUQ (dos conexiones) |
| 10 | `10_Indices.sql`: 3 consultas lentas, planes antes/después, índices y caso donde el índice no ayuda | TURISMOUQ |
| 11 | `11_SeguridadRolesPerfil.sql`: 4 roles, perfil con límites de sesión y usuarios | SYSTEM en XEPDB1 |
| 12 | `12_SeguridadVistasPrivilegios.sql`: vistas y privilegios de cada rol | TURISMOUQ |
| 13 | `13_PruebasSeguridad.sql`: se conecta con cada usuario y prueba sus permisos (ajustar `DEFINE conexion`) | cualquiera |

En SQL Developer, ejecutar cada script completo con **F5** (Ejecutar script) y activar la salida de DBMS_OUTPUT. Excepción: los pasos de 09a y 09b se ejecutan uno por uno (seleccionar el bloque del paso y F5), alternando entre las dos sesiones.

Documentación de cada entrega en `Documentacion/`.
