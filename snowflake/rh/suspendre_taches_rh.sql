-- À la fin du brief : arrêter les futurs départs automatiques de la chaîne.
-- Cela ne supprime aucun objet et n’annule pas une exécution déjà en cours.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
SHOW TASKS LIKE 'T_PURGE' IN SCHEMA NYC_TAXI.MARTS;
