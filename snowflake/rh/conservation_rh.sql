-- CAPTURE : conserver le tableau final des quatre rétentions avant de passer à la purge.
-- R2 : un jour de Time Travel sur les quatre tables contenant des chauffeurs.
-- TRANSFORMER possède les tables ; un tag de durée ne règle pas ce paramètre.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
ALTER TABLE NYC_TAXI.RAW.DRIVERS SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET DATA_RETENTION_TIME_IN_DAYS = 1;

SELECT table_schema, table_name, retention_time,
       IFF(retention_time = 1,'OK','ECHEC') AS statut
FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE (table_schema='RAW' AND table_name IN ('DRIVERS','DRIVER_SHIFTS'))
   OR (table_schema='MARTS' AND table_name IN ('DIM_DRIVER','MART_DRIVER_MONTHLY'))
ORDER BY table_schema, table_name;
-- Attendu : quatre lignes à 1 / OK. Les tables permanentes ont aussi un Fail-safe
-- de sept jours, non configurable : voir docs/VEILLE.md et REGISTRE.md.
