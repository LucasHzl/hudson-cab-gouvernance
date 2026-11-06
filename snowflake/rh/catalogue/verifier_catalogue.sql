USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
-- Cinq tables attendues, zéro description manquante.
SELECT table_schema, table_name, COUNT(*) AS colonnes,
       COUNT_IF(NULLIF(TRIM(comment), '') IS NULL) AS sans_description
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE (table_schema = 'RAW' AND table_name IN ('DRIVERS','DRIVER_SHIFTS'))
   OR (table_schema = 'MARTS' AND table_name IN ('DIM_DEPOT','DIM_DRIVER','MART_DRIVER_MONTHLY'))
GROUP BY 1,2 ORDER BY 1,2;
-- Attendu : 46 colonnes au total dans les cinq tables, toutes décrites.
SELECT table_name, column_name, description, donnee_personnelle,
       sensibilite, duree_conservation, personnelle_inventoriee, couverture_tag
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE ORDER BY table_name, ordinal_position;
