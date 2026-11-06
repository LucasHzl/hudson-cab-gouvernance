-- CAPTURE du tableau final : stage_fichiers=0, OK.
-- Lecture seule : ne recharge pas les données déjà purgées.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
LIST @NYC_TAXI.RAW.RH_STAGE;
SELECT 'stage_fichiers' AS controle, COUNT(*) AS obtenu, 0 AS attendu,
       IFF(COUNT(*)=0,'OK','ECHEC') AS statut
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
