-- Même requête, quatre rôles ; résultats agrégés publiables. Avant purge.
USE SECONDARY ROLES NONE;
USE ROLE RH_PAIE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif,
 COUNT(*) AS chauffeurs,
 COALESCE(COUNT_IF(first_name = '[MASQUE]'),0) AS prenoms_masques,
 COALESCE(COUNT_IF(birth_date IS NOT NULL),0) AS dates_completes_visibles,
 COALESCE(COUNT_IF(birth_year IS NOT NULL),0) AS annees_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;

USE SECONDARY ROLES NONE;
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif,
 COUNT(*) AS chauffeurs,
 COALESCE(COUNT_IF(first_name = '[MASQUE]'),0) AS prenoms_masques,
 COALESCE(COUNT_IF(birth_date IS NOT NULL),0) AS dates_completes_visibles,
 COALESCE(COUNT_IF(birth_year IS NOT NULL),0) AS annees_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;

USE SECONDARY ROLES NONE;
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif,
 COUNT(*) AS chauffeurs,
 COALESCE(COUNT_IF(first_name = '[MASQUE]'),0) AS prenoms_masques,
 COALESCE(COUNT_IF(birth_date IS NOT NULL),0) AS dates_completes_visibles,
 COALESCE(COUNT_IF(birth_year IS NOT NULL),0) AS annees_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;

USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
SELECT CURRENT_ROLE() AS role_actif,
 COUNT(*) AS chauffeurs,
 COALESCE(COUNT_IF(first_name = '[MASQUE]'),0) AS prenoms_masques,
 COALESCE(COUNT_IF(birth_date IS NOT NULL),0) AS dates_completes_visibles,
 COALESCE(COUNT_IF(birth_year IS NOT NULL),0) AS annees_visibles
FROM NYC_TAXI.MARTS.DIM_DRIVER;

-- Attendus RH_PAIE : 400 / 0 / 400 / 400 ; QUEENS : 161 / 0 / 0 / 0 ;
-- ANALYSTE : 400 / 400 / 0 / 400 ; ACCOUNTADMIN : 0 / 0 / 0 / 0.
