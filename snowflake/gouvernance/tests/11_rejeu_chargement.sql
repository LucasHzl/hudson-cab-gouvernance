-- CAPTURE du tableau final : deux rejeux, six contrôles attendus OK.
-- Une seule feuille, hors chargement/tâche actifs. Stage initial exigé vide.
-- Aucun dépôt de CSV historique, aucune réintroduction des chauffeurs purgés.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
LIST @NYC_TAXI.RAW.RH_STAGE;
SET rh_nb_fichiers_stage = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
EXECUTE IMMEDIATE $$
DECLARE stage_non_vide EXCEPTION (-20008,'Stage non vide : terminer le chargement avant le test de rejeu.');
BEGIN
 IF ($rh_nb_fichiers_stage <> 0) THEN RAISE stage_non_vide; END IF;
 RETURN 'Précondition : stage vide';
END;
$$;
SET r11_d_n = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS);
SET r11_d_h = (SELECT HASH_AGG(*) FROM NYC_TAXI.RAW.DRIVERS);
SET r11_s_n = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS);
SET r11_s_h = (SELECT HASH_AGG(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS);

-- Rejeu 1 du bloc exact du chargement.
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
SET r11_1_d = (SELECT IFF(COUNT(*)=$r11_d_n AND HASH_AGG(*)=$r11_d_h,1,0) FROM NYC_TAXI.RAW.DRIVERS);
SET r11_1_s = (SELECT IFF(COUNT(*)=$r11_s_n AND HASH_AGG(*)=$r11_s_h,1,0) FROM NYC_TAXI.RAW.DRIVER_SHIFTS);
LIST @NYC_TAXI.RAW.RH_STAGE;
SET r11_1_stage = (SELECT IFF(COUNT(*)=0,1,0) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

-- Rejeu 2 du bloc exact du chargement.
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
SET r11_2_d = (SELECT IFF(COUNT(*)=$r11_d_n AND HASH_AGG(*)=$r11_d_h,1,0) FROM NYC_TAXI.RAW.DRIVERS);
SET r11_2_s = (SELECT IFF(COUNT(*)=$r11_s_n AND HASH_AGG(*)=$r11_s_h,1,0) FROM NYC_TAXI.RAW.DRIVER_SHIFTS);
LIST @NYC_TAXI.RAW.RH_STAGE;
SET r11_2_stage = (SELECT IFF(COUNT(*)=0,1,0) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SELECT 'rejeu_1_drivers' AS controle, $r11_1_d AS obtenu, 1 AS attendu, IFF($r11_1_d=1,'OK','ECHEC') AS statut
UNION ALL
SELECT 'rejeu_1_driver_shifts' AS controle, $r11_1_s AS obtenu, 1 AS attendu, IFF($r11_1_s=1,'OK','ECHEC') AS statut
UNION ALL
SELECT 'rejeu_1_stage_vide' AS controle, $r11_1_stage AS obtenu, 1 AS attendu, IFF($r11_1_stage=1,'OK','ECHEC') AS statut
UNION ALL
SELECT 'rejeu_2_drivers' AS controle, $r11_2_d AS obtenu, 1 AS attendu, IFF($r11_2_d=1,'OK','ECHEC') AS statut
UNION ALL
SELECT 'rejeu_2_driver_shifts' AS controle, $r11_2_s AS obtenu, 1 AS attendu, IFF($r11_2_s=1,'OK','ECHEC') AS statut
UNION ALL
SELECT 'rejeu_2_stage_vide' AS controle, $r11_2_stage AS obtenu, 1 AS attendu, IFF($r11_2_stage=1,'OK','ECHEC') AS statut
ORDER BY controle;
