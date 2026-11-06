-- CAPTURE/EXPORT : tableau final uniquement. Ne lance aucune reconstruction.
-- Prérequis : chaîne complète terminée. Attentes écrites avant son exécution.
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
SET post_pol_raw_drivers = (SELECT COUNT(DISTINCT ref_column_name) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.RAW.DRIVERS', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='MASKING_POLICY' AND policy_status='ACTIVE');
SET post_rap_raw_drivers = (SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.RAW.DRIVERS', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='ROW_ACCESS_POLICY');
SET post_pol_raw_driver_shifts = (SELECT COUNT(DISTINCT ref_column_name) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.RAW.DRIVER_SHIFTS', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='MASKING_POLICY' AND policy_status='ACTIVE');
SET post_rap_raw_driver_shifts = (SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.RAW.DRIVER_SHIFTS', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='ROW_ACCESS_POLICY');
SET post_pol_marts_dim_driver = (SELECT COUNT(DISTINCT ref_column_name) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='MASKING_POLICY' AND policy_status='ACTIVE');
SET post_rap_marts_dim_driver = (SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='ROW_ACCESS_POLICY');
SET post_pol_marts_mart_driver_monthly = (SELECT COUNT(DISTINCT ref_column_name) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='MASKING_POLICY' AND policy_status='ACTIVE');
SET post_rap_marts_mart_driver_monthly = (SELECT COUNT(*) FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', REF_ENTITY_DOMAIN => 'TABLE')) WHERE policy_kind='ROW_ACCESS_POLICY');
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SET post_driver_source = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS);
SET post_driver_dim = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET post_driver_expires = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year,-5,CURRENT_DATE()));
SET post_emails_masques = (SELECT COALESCE(COUNT_IF(email='[MASQUE]'),0) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET post_emails_differents = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER d LEFT JOIN NYC_TAXI.STAGING.STG_RH__DRIVERS s ON d.driver_id=s.driver_id WHERE s.driver_id IS NULL OR d.email IS DISTINCT FROM s.email);
SET post_descriptions = (SELECT COUNT(*) FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE ((table_schema='RAW' AND table_name IN ('DRIVERS','DRIVER_SHIFTS')) OR (table_schema='MARTS' AND table_name IN ('DIM_DRIVER','DIM_DEPOT','MART_DRIVER_MONTHLY'))) AND NULLIF(TRIM(comment),'') IS NULL);
SET post_retention = (SELECT COUNT(*) FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES WHERE ((table_schema='RAW' AND table_name IN ('DRIVERS','DRIVER_SHIFTS')) OR (table_schema='MARTS' AND table_name IN ('DIM_DRIVER','MART_DRIVER_MONTHLY'))) AND retention_time=1);
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SET post_catalogue = (SELECT COUNT(*) FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE);
SET post_prenoms = (SELECT COALESCE(COUNT_IF(first_name='[MASQUE]'),0) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET post_dates = (SELECT COALESCE(COUNT_IF(birth_date IS NOT NULL),0) FROM NYC_TAXI.MARTS.DIM_DRIVER);
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
SET post_admin = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SELECT 'masques_raw_drivers' AS controle, $post_pol_raw_drivers AS obtenu, 9 AS attendu, IFF($post_pol_raw_drivers=9,'OK','ECHEC') AS statut
UNION ALL SELECT 'filtre_raw_drivers' AS controle, $post_rap_raw_drivers AS obtenu, 1 AS attendu, IFF($post_rap_raw_drivers=1,'OK','ECHEC') AS statut
UNION ALL SELECT 'masques_raw_driver_shifts' AS controle, $post_pol_raw_driver_shifts AS obtenu, 7 AS attendu, IFF($post_pol_raw_driver_shifts=7,'OK','ECHEC') AS statut
UNION ALL SELECT 'filtre_raw_driver_shifts' AS controle, $post_rap_raw_driver_shifts AS obtenu, 1 AS attendu, IFF($post_rap_raw_driver_shifts=1,'OK','ECHEC') AS statut
UNION ALL SELECT 'masques_marts_dim_driver' AS controle, $post_pol_marts_dim_driver AS obtenu, 12 AS attendu, IFF($post_pol_marts_dim_driver=12,'OK','ECHEC') AS statut
UNION ALL SELECT 'filtre_marts_dim_driver' AS controle, $post_rap_marts_dim_driver AS obtenu, 1 AS attendu, IFF($post_rap_marts_dim_driver=1,'OK','ECHEC') AS statut
UNION ALL SELECT 'masques_marts_mart_driver_monthly' AS controle, $post_pol_marts_mart_driver_monthly AS obtenu, 7 AS attendu, IFF($post_pol_marts_mart_driver_monthly=7,'OK','ECHEC') AS statut
UNION ALL SELECT 'filtre_marts_mart_driver_monthly' AS controle, $post_rap_marts_mart_driver_monthly AS obtenu, 1 AS attendu, IFF($post_rap_marts_mart_driver_monthly=1,'OK','ECHEC') AS statut
UNION ALL SELECT 'chauffeurs_source_et_dimension' AS controle, $post_driver_dim AS obtenu, $post_driver_source AS attendu, IFF($post_driver_dim=$post_driver_source,'OK','ECHEC') AS statut
UNION ALL SELECT 'chauffeurs_expires' AS controle, $post_driver_expires AS obtenu, 0 AS attendu, IFF($post_driver_expires=0,'OK','ECHEC') AS statut
UNION ALL SELECT 'emails_masques_pipeline' AS controle, $post_emails_masques AS obtenu, 0 AS attendu, IFF($post_emails_masques=0,'OK','ECHEC') AS statut
UNION ALL SELECT 'emails_differents_source' AS controle, $post_emails_differents AS obtenu, 0 AS attendu, IFF($post_emails_differents=0,'OK','ECHEC') AS statut
UNION ALL SELECT 'descriptions_manquantes' AS controle, $post_descriptions AS obtenu, 0 AS attendu, IFF($post_descriptions=0,'OK','ECHEC') AS statut
UNION ALL SELECT 'tables_retention_un_jour' AS controle, $post_retention AS obtenu, 4 AS attendu, IFF($post_retention=4,'OK','ECHEC') AS statut
UNION ALL SELECT 'catalogue_lisible_analyste' AS controle, $post_catalogue AS obtenu, 25 AS attendu, IFF($post_catalogue=25,'OK','ECHEC') AS statut
UNION ALL SELECT 'prenoms_masques_analyste' AS controle, $post_prenoms AS obtenu, $post_driver_source AS attendu, IFF($post_prenoms=$post_driver_source,'OK','ECHEC') AS statut
UNION ALL SELECT 'dates_completes_analyste' AS controle, $post_dates AS obtenu, 0 AS attendu, IFF($post_dates=0,'OK','ECHEC') AS statut
UNION ALL SELECT 'chauffeurs_admin' AS controle, $post_admin AS obtenu, 0 AS attendu, IFF($post_admin=0,'OK','ECHEC') AS statut
ORDER BY controle;
