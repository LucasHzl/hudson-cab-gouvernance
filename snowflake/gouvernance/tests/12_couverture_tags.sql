-- Attentes écrites avant la migration : 39 colonnes personnelles, zéro manque.
-- CAPTURE du tableau final : cinq lignes attendues OK (quatre tables et catalogue).
-- Lecture seule, aucun nom ni coordonnée de chauffeur dans le résultat.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
WITH attendues AS (
 SELECT column1 AS schema_nom,column2 AS table_nom,column3 AS colonne,column4 AS nature
 FROM VALUES
('RAW','DRIVERS','DRIVER_ID','identifiant_interne'),
('RAW','DRIVERS','FIRST_NAME','nom'),
('RAW','DRIVERS','LAST_NAME','nom'),
('RAW','DRIVERS','EMAIL','email'),
('RAW','DRIVERS','PHONE','telephone'),
('RAW','DRIVERS','BIRTH_DATE','date_naissance'),
('RAW','DRIVERS','TLC_LICENSE_NUMBER','identifiant_officiel'),
('RAW','DRIVERS','DEPOT','donnee_professionnelle'),
('RAW','DRIVERS','HIRE_DATE','donnee_professionnelle'),
('RAW','DRIVERS','END_DATE','donnee_professionnelle'),
('RAW','DRIVER_SHIFTS','SHIFT_ID','identifiant_interne'),
('RAW','DRIVER_SHIFTS','DRIVER_ID','identifiant_interne'),
('RAW','DRIVER_SHIFTS','SHIFT_DATE','activite'),
('RAW','DRIVER_SHIFTS','DEPOT','donnee_professionnelle'),
('RAW','DRIVER_SHIFTS','START_HOUR','activite'),
('RAW','DRIVER_SHIFTS','HOURS_WORKED','activite'),
('RAW','DRIVER_SHIFTS','TRIPS_COUNT','activite'),
('RAW','DRIVER_SHIFTS','REVENUE_USD','activite'),
('MARTS','DIM_DRIVER','DRIVER_ID','identifiant_interne'),
('MARTS','DIM_DRIVER','FIRST_NAME','nom'),
('MARTS','DIM_DRIVER','LAST_NAME','nom'),
('MARTS','DIM_DRIVER','EMAIL','email'),
('MARTS','DIM_DRIVER','PHONE','telephone'),
('MARTS','DIM_DRIVER','BIRTH_DATE','date_naissance'),
('MARTS','DIM_DRIVER','TLC_LICENSE_NUMBER','identifiant_officiel'),
('MARTS','DIM_DRIVER','DEPOT','donnee_professionnelle'),
('MARTS','DIM_DRIVER','HIRE_DATE','donnee_professionnelle'),
('MARTS','DIM_DRIVER','END_DATE','donnee_professionnelle'),
('MARTS','DIM_DRIVER','IS_ACTIVE','donnee_professionnelle'),
('MARTS','DIM_DRIVER','TENURE_YEARS','donnee_professionnelle'),
('MARTS','DIM_DRIVER','BIRTH_YEAR','date_naissance'),
('MARTS','MART_DRIVER_MONTHLY','ACTIVITY_MONTH','activite'),
('MARTS','MART_DRIVER_MONTHLY','DRIVER_ID','identifiant_interne'),
('MARTS','MART_DRIVER_MONTHLY','DRIVER_NAME','nom'),
('MARTS','MART_DRIVER_MONTHLY','DEPOT','donnee_professionnelle'),
('MARTS','MART_DRIVER_MONTHLY','NB_SHIFTS','activite'),
('MARTS','MART_DRIVER_MONTHLY','HOURS_WORKED','activite'),
('MARTS','MART_DRIVER_MONTHLY','TRIPS_COUNT','activite'),
('MARTS','MART_DRIVER_MONTHLY','REVENUE_USD','activite')
), tags AS (
SELECT object_schema,object_name,column_name,tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVERS','TABLE')) WHERE tag_database='NYC_TAXI' AND tag_schema='GOUVERNANCE' AND tag_name='DONNEE_PERSONNELLE'
UNION ALL
SELECT object_schema,object_name,column_name,tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVER_SHIFTS','TABLE')) WHERE tag_database='NYC_TAXI' AND tag_schema='GOUVERNANCE' AND tag_name='DONNEE_PERSONNELLE'
UNION ALL
SELECT object_schema,object_name,column_name,tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER','TABLE')) WHERE tag_database='NYC_TAXI' AND tag_schema='GOUVERNANCE' AND tag_name='DONNEE_PERSONNELLE'
UNION ALL
SELECT object_schema,object_name,column_name,tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY','TABLE')) WHERE tag_database='NYC_TAXI' AND tag_schema='GOUVERNANCE' AND tag_name='DONNEE_PERSONNELLE'
), mesures AS (
 SELECT a.schema_nom,a.table_nom,a.colonne,a.nature,
        t.tag_value AS nature_obtenue, c.comment
 FROM attendues a
 LEFT JOIN tags t ON t.object_schema=a.schema_nom AND t.object_name=a.table_nom
   AND t.column_name=a.colonne
 LEFT JOIN NYC_TAXI.INFORMATION_SCHEMA.COLUMNS c
 ON c.table_schema=a.schema_nom AND c.table_name=a.table_nom AND c.column_name=a.colonne
), par_table AS (
 SELECT schema_nom||'.'||table_nom AS controle,COUNT(*) AS colonnes_attendues,
        COUNT_IF(nature_obtenue=nature AND comment LIKE 'Donnée personnelle.%') AS colonnes_conformes
 FROM mesures GROUP BY schema_nom,table_nom
)
SELECT controle,colonnes_attendues,COALESCE(colonnes_conformes,0) AS colonnes_conformes,
       colonnes_attendues-COALESCE(colonnes_conformes,0) AS ecarts,
       IFF(COALESCE(colonnes_conformes,0)=colonnes_attendues,'OK','ECHEC') AS statut
FROM par_table
UNION ALL
SELECT 'V_CATALOGUE_PERSONNEL',21,
       COALESCE(COUNT_IF(personnelle_inventoriee AND donnee_personnelle IS NOT NULL AND couverture_tag='OK'),0),
       21-COALESCE(COUNT_IF(personnelle_inventoriee AND donnee_personnelle IS NOT NULL AND couverture_tag='OK'),0),
       IFF(COUNT(*)=25 AND COUNT_IF(personnelle_inventoriee)=21
           AND COALESCE(COUNT_IF(couverture_tag<>'OK'),0)=0,'OK','ECHEC')
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
ORDER BY controle;
