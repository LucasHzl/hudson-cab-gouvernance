-- CAPTURE éventuelle après les tâches : lecture seule, aucune nouvelle mesure.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SELECT regle,mesure_le,nb_anomalies,seuil,statut
FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
WHERE mesure_le=(SELECT MAX(mesure_le) FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS)
ORDER BY regle;
