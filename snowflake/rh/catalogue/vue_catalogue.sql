-- Trois tables MARTS, une ligne par colonne. Pas de valeurs RH dans ce catalogue.
-- À rejouer après tout ajout de colonne ou modification de structure.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

CREATE OR REPLACE VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE AS
WITH tags AS (
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER', 'table'))
    UNION ALL
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'table'))
    UNION ALL
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DEPOT', 'table'))
), natures AS (
    SELECT object_schema, object_name, column_name, MAX(tag_value) AS donnee_personnelle
    FROM tags WHERE tag_name = 'DONNEE_PERSONNELLE'
    GROUP BY 1, 2, 3
), tables_tags AS (
    SELECT 'DIM_DRIVER' AS nom_table,
      SYSTEM$GET_TAG('NYC_TAXI.GOUVERNANCE.SENSIBILITE', 'NYC_TAXI.MARTS.DIM_DRIVER', 'TABLE') AS sensibilite,
      SYSTEM$GET_TAG('NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION', 'NYC_TAXI.MARTS.DIM_DRIVER', 'TABLE') AS duree_conservation
    UNION ALL
    SELECT 'MART_DRIVER_MONTHLY',
      SYSTEM$GET_TAG('NYC_TAXI.GOUVERNANCE.SENSIBILITE', 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'TABLE'),
      SYSTEM$GET_TAG('NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION', 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'TABLE')
    UNION ALL
    SELECT 'DIM_DEPOT',
      SYSTEM$GET_TAG('NYC_TAXI.GOUVERNANCE.SENSIBILITE', 'NYC_TAXI.MARTS.DIM_DEPOT', 'TABLE'),
      SYSTEM$GET_TAG('NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION', 'NYC_TAXI.MARTS.DIM_DEPOT', 'TABLE')
)
SELECT c.table_schema, c.table_name, t.comment AS description_table,
       c.column_name, c.ordinal_position, c.data_type, c.comment AS description,
       g.donnee_personnelle, tt.sensibilite, tt.duree_conservation,
       COALESCE(c.comment LIKE 'Donnée personnelle.%', FALSE) AS personnelle_inventoriee,
       CASE WHEN c.comment LIKE 'Donnée personnelle.%' AND g.donnee_personnelle IS NULL
            THEN 'ECART_TAG_CONTRAT' ELSE 'OK' END AS couverture_tag
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS c
JOIN NYC_TAXI.INFORMATION_SCHEMA.TABLES t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
JOIN tables_tags tt ON tt.nom_table = c.table_name
LEFT JOIN natures g ON g.object_schema = c.table_schema
  AND g.object_name = c.table_name AND g.column_name = c.column_name
WHERE c.table_schema = 'MARTS';

COMMENT ON VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE IS
  'Catalogue des trois tables RH de MARTS : descriptions et tags ; les colonnes personnelles sans tag adapté sont signalées, pas déclarées non personnelles.';

SELECT table_name, COUNT(*) AS colonnes, COUNT_IF(description IS NULL) AS sans_description
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE GROUP BY table_name ORDER BY table_name;
-- Attendu avant ajout éventuel de colonne : DIM_DEPOT 4, DIM_DRIVER 13, MART_DRIVER_MONTHLY 8 ; zéro sans_description.
