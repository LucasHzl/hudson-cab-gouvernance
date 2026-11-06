-- A16 : tester après 03 et 04 ; exécuter bloc par bloc dans la même session.
-- Aucun changement du corps de la politique ; modification de la seule table.
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
-- Attendu avant test : aucune entrée Queens/Bronx. Si elle existe déjà, ne pas
-- la supprimer : choisir une autre extension et calculer ses références.
SELECT COUNT(*) AS entree_deja_presente
FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT
WHERE role_name = 'RESP_DEPOT_QUEENS' AND depot = 'Bronx';
-- Continuer uniquement si zéro.
BEGIN TRANSACTION;
INSERT INTO NYC_TAXI.GOUVERNANCE.ACCES_DEPOT VALUES ('RESP_DEPOT_QUEENS','Bronx');
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) AS chauffeurs FROM NYC_TAXI.MARTS.DIM_DRIVER;
SELECT COUNT(*) AS lignes_mensuelles FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
-- Attendu avant purge : 283 chauffeurs et 655 lignes mensuelles.
USE ROLE GOUVERNANCE;
ROLLBACK;
-- Le ROLLBACK annule l’INSERT de ce test et restaure le mapping.
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) AS chauffeurs FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- Retour attendu : 161.
