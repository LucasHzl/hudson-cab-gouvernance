-- Avant purge : reconstruire MARTS avec le rôle des outils, puis contrôler
-- valeurs, métadonnées et accès. Résultat final unique, agrégé et publiable.
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
SET test_rejeu_politiques_avant = (
 SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
 REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE')));
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SET test_rejeu_tags_avant = (
 SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
 'NYC_TAXI.MARTS.DIM_DRIVER','table')));

-- Même instruction que rh/marts/dim_depot.sql
INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DEPOT (depot, quartier, ouvert_en, nb_places) VALUES
    ('Bronx',    'Hunts Point',       2009, 140),
    ('Brooklyn', 'East New York',     2011, 120),
    ('Queens',   'Long Island City',  2008, 180);


-- Même instruction que rh/marts/dim_driver.sql
INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DRIVER (
    driver_id, first_name, last_name, email, phone, birth_date,
    tlc_license_number, depot, hire_date, end_date, is_active, tenure_years, birth_year
)
SELECT
    driver_id,
    first_name,
    last_name,
    email,
    phone,
    birth_date,
    tlc_license_number,
    depot,
    hire_date,
    end_date,
    end_date IS NULL                                                          AS is_active,
    ROUND(DATEDIFF(day, hire_date, COALESCE(end_date, CURRENT_DATE())) / 365.25, 1) AS tenure_years,
    YEAR(birth_date) AS birth_year
FROM NYC_TAXI.STAGING.STG_RH__DRIVERS;


-- Même instruction que rh/marts/mart_driver_monthly.sql
INSERT OVERWRITE INTO NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
SELECT
    DATE_TRUNC('month', s.shift_date)::date     AS activity_month,
    s.driver_id,
    d.first_name || ' ' || d.last_name          AS driver_name,
    s.depot,
    COUNT(*)                                    AS nb_shifts,
    ROUND(SUM(s.hours_worked), 1)               AS hours_worked,
    SUM(s.trips_count)                          AS trips_count,
    ROUND(SUM(s.revenue_usd), 2)                AS revenue_usd
FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS s
LEFT JOIN NYC_TAXI.MARTS.DIM_DRIVER d ON d.driver_id = s.driver_id
GROUP BY 1, 2, 3, 4;


SET test_rejeu_chauffeurs = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET test_rejeu_mensuel = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY);
SET test_rejeu_emails_masques = (SELECT COALESCE(COUNT_IF(email = '[MASQUE]'),0) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET test_rejeu_emails_differents = (
 SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER d
 LEFT JOIN NYC_TAXI.STAGING.STG_RH__DRIVERS s ON d.driver_id=s.driver_id
 WHERE s.driver_id IS NULL OR d.email IS DISTINCT FROM s.email);
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
SET test_rejeu_politiques_apres = (
 SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
 REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE')));
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SET test_rejeu_tags_apres = (
 SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
 'NYC_TAXI.MARTS.DIM_DRIVER','table')));
SET test_rejeu_descriptions = (
 SELECT COALESCE(COUNT_IF(NULLIF(TRIM(comment),'') IS NULL),0) FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
 WHERE table_schema='MARTS' AND table_name='DIM_DRIVER');

USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SET test_rejeu_prenoms = (SELECT COALESCE(COUNT_IF(first_name='[MASQUE]'),0) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET test_rejeu_dates = (SELECT COALESCE(COUNT_IF(birth_date IS NOT NULL),0) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET test_rejeu_annees = (SELECT COALESCE(COUNT_IF(birth_year IS NOT NULL),0) FROM NYC_TAXI.MARTS.DIM_DRIVER);
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SET test_rejeu_queens = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
SET test_rejeu_admin = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

SELECT 'chauffeurs_reconstruits' AS controle, $test_rejeu_chauffeurs AS obtenu, 400 AS attendu, IFF($test_rejeu_chauffeurs=400,'OK','ECHEC') AS statut
UNION ALL SELECT 'mensuel_reconstruit',$test_rejeu_mensuel,914,IFF($test_rejeu_mensuel=914,'OK','ECHEC')
UNION ALL SELECT 'emails_masques_pipeline',$test_rejeu_emails_masques,0,IFF($test_rejeu_emails_masques=0,'OK','ECHEC')
UNION ALL SELECT 'emails_differents_source',$test_rejeu_emails_differents,0,IFF($test_rejeu_emails_differents=0,'OK','ECHEC')
UNION ALL SELECT 'politiques_DIM_DRIVER',$test_rejeu_politiques_apres,$test_rejeu_politiques_avant,IFF($test_rejeu_politiques_apres=$test_rejeu_politiques_avant AND $test_rejeu_politiques_avant>0,'OK','ECHEC')
UNION ALL SELECT 'tags_DIM_DRIVER',$test_rejeu_tags_apres,$test_rejeu_tags_avant,IFF($test_rejeu_tags_apres=$test_rejeu_tags_avant AND $test_rejeu_tags_avant>0,'OK','ECHEC')
UNION ALL SELECT 'descriptions_manquantes_DIM_DRIVER',$test_rejeu_descriptions,0,IFF($test_rejeu_descriptions=0,'OK','ECHEC')
UNION ALL SELECT 'analyste_prenoms_masques',$test_rejeu_prenoms,400,IFF($test_rejeu_prenoms=400,'OK','ECHEC')
UNION ALL SELECT 'analyste_dates_completes',$test_rejeu_dates,0,IFF($test_rejeu_dates=0,'OK','ECHEC')
UNION ALL SELECT 'analyste_annees_visibles',$test_rejeu_annees,400,IFF($test_rejeu_annees=400,'OK','ECHEC')
UNION ALL SELECT 'queens_apres_reconstruction',$test_rejeu_queens,161,IFF($test_rejeu_queens=161,'OK','ECHEC')
UNION ALL SELECT 'admin_apres_reconstruction',$test_rejeu_admin,0,IFF($test_rejeu_admin=0,'OK','ECHEC')
ORDER BY controle;
