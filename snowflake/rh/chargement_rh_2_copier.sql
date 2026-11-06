-- Étape 2 : chargement RH avec les deux COPY fournis, sans FORCE.
-- Exécuter entier après chargement_rh_1_preparer.sql et dépôt des deux CSV.
-- Stage vide après un premier chargement : rejeu sans modification des tables.
-- Si les fichiers sont présents, COPY garde son mécanisme de suivi des fichiers.
-- Un nouveau fichier complet impose une purge AVANT reconstruction et ouverture.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
LIST @NYC_TAXI.RAW.RH_STAGE;
SET rh_nb_fichiers_stage = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
EXECUTE IMMEDIATE $$
DECLARE
 fichiers NUMBER DEFAULT $rh_nb_fichiers_stage;
BEGIN
 IF (fichiers = 0) THEN
  RETURN 'Stage vide : aucun fichier à copier, données existantes conservées';
 END IF;
COPY INTO NYC_TAXI.RAW.DRIVERS
FROM (SELECT $1, $2, $3, $4, $5, $6::date, $7, $8, $9::date, $10::date,
             METADATA$FILENAME, METADATA$START_SCAN_TIME::timestamp_ntz
      FROM @NYC_TAXI.RAW.RH_STAGE)
FILES = ('drivers.csv')
FILE_FORMAT = (FORMAT_NAME = NYC_TAXI.RAW.CSV_RH)
ON_ERROR = ABORT_STATEMENT
PURGE = TRUE;

COPY INTO NYC_TAXI.RAW.DRIVER_SHIFTS
FROM (SELECT $1, $2, $3::date, $4, $5::integer, $6::float, $7::integer, $8::float,
             METADATA$FILENAME, METADATA$START_SCAN_TIME::timestamp_ntz
      FROM @NYC_TAXI.RAW.RH_STAGE)
FILES = ('driver_shifts.csv')
FILE_FORMAT = (FORMAT_NAME = NYC_TAXI.RAW.CSV_RH)
ON_ERROR = ABORT_STATEMENT
PURGE = TRUE;
 RETURN 'Chargement des fichiers RH terminé ; vérifier les volumes et le stage';
END;
$$;
SELECT (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS chauffeurs,
       (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS services;
-- Chargement initial : 400 / 25951 ; après la purge du 6/11/2026 : 354 / 25951.
LIST @NYC_TAXI.RAW.RH_STAGE;
