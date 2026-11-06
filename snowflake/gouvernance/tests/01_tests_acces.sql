-- Cahier exécutable écrit AVANT les politiques : voir docs/ACCES.md.
-- Exécuter les blocs séparément et consigner obtenu. Avant protection,
-- plusieurs tests doivent échouer : c’est la phase rouge attendue.
-- Préconditions : 02_roles_metier.sql, rh/01_annee_naissance.sql ; 400 chauffeurs,
-- avant la purge. Aucun résultat ci-dessous ne contient de valeur RH nominative.
-- Les tests REFUS sont séparés : une erreur attendue arrête un Run All.

-- RH_PAIE : DIM_DRIVER 400, MART_DRIVER_MONTHLY 914 lignes.
USE SECONDARY ROLES NONE;
USE ROLE RH_PAIE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS chauffeurs,
       0 AS hors_perimetre,
       COUNT_IF(first_name = '[MASQUE]') AS prenoms_masques,
       COUNT_IF(last_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(email IS NOT NULL AND email <> '[MASQUE]') AS emails_en_clair,
       COUNT_IF(phone IS NOT NULL AND phone <> '[MASQUE]') AS telephones_en_clair,
       COUNT_IF(birth_date IS NOT NULL) AS dates_naissance_visibles,
       COUNT_IF(birth_year IS NOT NULL) AS annees_naissance_visibles,
       COUNT_IF(tlc_license_number IS NOT NULL AND tlc_license_number <> '[MASQUE]') AS licences_en_clair,
       COUNT_IF(hire_date IS NOT NULL) AS dates_embauche_visibles,
       COUNT_IF(tenure_years IS NOT NULL) AS anciennetes_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS lignes_mensuelles,
       0 AS hors_perimetre,
       COUNT_IF(driver_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(revenue_usd IS NOT NULL) AS recettes_visibles,
       COUNT_IF(hours_worked IS NOT NULL) AS heures_visibles
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
SELECT COUNT(*) AS depots_referentiel FROM NYC_TAXI.MARTS.DIM_DEPOT;
-- Attendu DIM_DEPOT : 3 pour tous les rôles métier.

-- RESP_DEPOT_QUEENS : DIM_DRIVER 161, MART_DRIVER_MONTHLY 365 lignes.
USE SECONDARY ROLES NONE;
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS chauffeurs,
       COUNT_IF(depot IS NULL OR depot <> 'Queens') AS hors_perimetre,
       COUNT_IF(first_name = '[MASQUE]') AS prenoms_masques,
       COUNT_IF(last_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(email IS NOT NULL AND email <> '[MASQUE]') AS emails_en_clair,
       COUNT_IF(phone IS NOT NULL AND phone <> '[MASQUE]') AS telephones_en_clair,
       COUNT_IF(birth_date IS NOT NULL) AS dates_naissance_visibles,
       COUNT_IF(birth_year IS NOT NULL) AS annees_naissance_visibles,
       COUNT_IF(tlc_license_number IS NOT NULL AND tlc_license_number <> '[MASQUE]') AS licences_en_clair,
       COUNT_IF(hire_date IS NOT NULL) AS dates_embauche_visibles,
       COUNT_IF(tenure_years IS NOT NULL) AS anciennetes_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS lignes_mensuelles,
       COUNT_IF(depot IS NULL OR depot <> 'Queens') AS hors_perimetre,
       COUNT_IF(driver_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(revenue_usd IS NOT NULL) AS recettes_visibles,
       COUNT_IF(hours_worked IS NOT NULL) AS heures_visibles
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
SELECT COUNT(*) AS depots_referentiel FROM NYC_TAXI.MARTS.DIM_DEPOT;
-- Attendu DIM_DEPOT : 3 pour tous les rôles métier.

-- RESP_DEPOT_BRONX : DIM_DRIVER 122, MART_DRIVER_MONTHLY 290 lignes.
USE SECONDARY ROLES NONE;
USE ROLE RESP_DEPOT_BRONX;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS chauffeurs,
       COUNT_IF(depot IS NULL OR depot <> 'Bronx') AS hors_perimetre,
       COUNT_IF(first_name = '[MASQUE]') AS prenoms_masques,
       COUNT_IF(last_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(email IS NOT NULL AND email <> '[MASQUE]') AS emails_en_clair,
       COUNT_IF(phone IS NOT NULL AND phone <> '[MASQUE]') AS telephones_en_clair,
       COUNT_IF(birth_date IS NOT NULL) AS dates_naissance_visibles,
       COUNT_IF(birth_year IS NOT NULL) AS annees_naissance_visibles,
       COUNT_IF(tlc_license_number IS NOT NULL AND tlc_license_number <> '[MASQUE]') AS licences_en_clair,
       COUNT_IF(hire_date IS NOT NULL) AS dates_embauche_visibles,
       COUNT_IF(tenure_years IS NOT NULL) AS anciennetes_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS lignes_mensuelles,
       COUNT_IF(depot IS NULL OR depot <> 'Bronx') AS hors_perimetre,
       COUNT_IF(driver_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(revenue_usd IS NOT NULL) AS recettes_visibles,
       COUNT_IF(hours_worked IS NOT NULL) AS heures_visibles
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
SELECT COUNT(*) AS depots_referentiel FROM NYC_TAXI.MARTS.DIM_DEPOT;
-- Attendu DIM_DEPOT : 3 pour tous les rôles métier.

-- ANALYSTE : DIM_DRIVER 400, MART_DRIVER_MONTHLY 914 lignes.
USE SECONDARY ROLES NONE;
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS chauffeurs,
       0 AS hors_perimetre,
       COUNT_IF(first_name = '[MASQUE]') AS prenoms_masques,
       COUNT_IF(last_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(email IS NOT NULL AND email <> '[MASQUE]') AS emails_en_clair,
       COUNT_IF(phone IS NOT NULL AND phone <> '[MASQUE]') AS telephones_en_clair,
       COUNT_IF(birth_date IS NOT NULL) AS dates_naissance_visibles,
       COUNT_IF(birth_year IS NOT NULL) AS annees_naissance_visibles,
       COUNT_IF(tlc_license_number IS NOT NULL AND tlc_license_number <> '[MASQUE]') AS licences_en_clair,
       COUNT_IF(hire_date IS NOT NULL) AS dates_embauche_visibles,
       COUNT_IF(tenure_years IS NOT NULL) AS anciennetes_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;
SELECT CURRENT_ROLE() AS role_actif, COUNT(*) AS lignes_mensuelles,
       0 AS hors_perimetre,
       COUNT_IF(driver_name = '[MASQUE]') AS noms_masques,
       COUNT_IF(revenue_usd IS NOT NULL) AS recettes_visibles,
       COUNT_IF(hours_worked IS NOT NULL) AS heures_visibles
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
SELECT COUNT(*) AS depots_referentiel FROM NYC_TAXI.MARTS.DIM_DEPOT;
-- Attendu DIM_DEPOT : 3 pour tous les rôles métier.

-- Catalogue lu par un métier : 25 lignes après ajout de birth_year, 3 tables.
USE SECONDARY ROLES NONE;
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) AS colonnes, COUNT(DISTINCT table_name) AS tables,
       COUNT_IF(description IS NULL) AS descriptions_absentes,
       COUNT_IF(couverture_tag <> 'OK') AS ecarts_taxonomie_signales
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE;
-- Attendu : 25, 3, 0, 11. Les 11 écarts ne sont pas cachés.

-- ACCOUNTADMIN hérite de TRANSFORMER par SYSADMIN : SELECT autorisé,
-- mais la future politique doit ne lui laisser aucune ligne RH.
USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) AS chauffeurs FROM NYC_TAXI.MARTS.DIM_DRIVER;
SELECT COUNT(*) AS services FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
-- Attendu après politiques : 0 et 0.

-- REFUS 1 : lancer ce bloc seul. GOUVERNANCE ne lit pas le personnel.
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- Attendu : erreur d’autorisation ; pas seulement zéro ligne.

-- REFUS 2 : lancer ce bloc seul. La paie ne lit pas RAW.
USE SECONDARY ROLES NONE;
USE ROLE RH_PAIE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
-- Attendu : erreur d’autorisation.

-- REFUS 3 : lancer ce bloc seul. L’analyste ne lit pas RAW.
USE SECONDARY ROLES NONE;
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS;
-- Attendu : erreur d’autorisation.

-- Pipeline : après reconstruction, TRANSFORMER doit toujours voir les valeurs
-- nécessaires. Comparer les emails sans les afficher dans les résultats.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) AS chauffeurs,
       COUNT_IF(email = '[MASQUE]') AS emails_deja_masques,
       COUNT_IF(birth_year IS DISTINCT FROM YEAR(birth_date)) AS annees_incoherentes
FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- Attendu avant purge : 400, 0, 0.
SELECT COUNT(*) AS emails_differents_de_la_source
FROM NYC_TAXI.MARTS.DIM_DRIVER d
JOIN NYC_TAXI.STAGING.STG_RH__DRIVERS s ON d.driver_id = s.driver_id
WHERE d.email IS DISTINCT FROM s.email;
-- Attendu : 0. À répéter après relance des scripts de transformation.
