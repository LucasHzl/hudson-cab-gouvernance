-- Test A16 avant OU après purge. Exécuter entier dans une même feuille.
-- CAPTURE : tableau final des trois étapes, toutes attendues OK.
-- Références calculées avec TRANSFORMER, puis comparées aux lectures du responsable.
-- Exécuter hors reconstruction active ; ne change que le mapping temporaire.
-- Le tableau final rassemble les trois étapes : pas besoin de chercher les onglets.
-- On ajoute puis retire uniquement l’entrée de test ; aucune politique modifiée.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SET map_ref_queens_drivers = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE depot='Queens');
SET map_ref_queens_monthly = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE depot='Queens');
SET map_ref_etendu_drivers = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE depot IN ('Queens','Bronx'));
SET map_ref_etendu_monthly = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE depot IN ('Queens','Bronx'));
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
EXECUTE IMMEDIATE $$
DECLARE
 nb NUMBER;
 entree_existante EXCEPTION (-20002, 'Le mapping Queens/Bronx existe déjà : ne pas écraser cette habilitation.');
BEGIN
 SELECT COUNT(*) INTO :nb FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT
 WHERE role_name = 'RESP_DEPOT_QUEENS' AND depot = 'Bronx';
 IF (nb <> 0) THEN RAISE entree_existante; END IF;
 RETURN 'Précondition OK : aucune entrée de test existante';
END;
$$;

USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SET test_map_avant_chauffeurs = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET test_map_avant_mensuel = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY);

USE ROLE GOUVERNANCE;
BEGIN TRANSACTION;
INSERT INTO NYC_TAXI.GOUVERNANCE.ACCES_DEPOT VALUES ('RESP_DEPOT_QUEENS','Bronx');
COMMIT;
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SET test_map_etendu_chauffeurs = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET test_map_etendu_mensuel = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY);

-- Nettoyage de la seule ligne introduite, dont l’absence initiale a été vérifiée.
-- Si une étape précédente échoue après l’INSERT, reprendre ce bloc de nettoyage.
USE ROLE GOUVERNANCE;
BEGIN TRANSACTION;
DELETE FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT
WHERE role_name = 'RESP_DEPOT_QUEENS' AND depot = 'Bronx';
COMMIT;
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SET test_map_retour_chauffeurs = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER);
SET test_map_retour_mensuel = (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY);

SELECT 1 AS ordre, 'QUEENS_AVANT' AS etape,
 $test_map_avant_chauffeurs AS chauffeurs, $test_map_avant_mensuel AS lignes_mensuelles,
 $map_ref_queens_drivers AS chauffeurs_attendus, $map_ref_queens_monthly AS lignes_attendues,
 IFF($test_map_avant_chauffeurs=$map_ref_queens_drivers AND $test_map_avant_mensuel=$map_ref_queens_monthly,'OK','ECHEC') AS statut
UNION ALL
SELECT 2, 'QUEENS_PLUS_BRONX', $test_map_etendu_chauffeurs, $test_map_etendu_mensuel,
 $map_ref_etendu_drivers, $map_ref_etendu_monthly, IFF($test_map_etendu_chauffeurs=$map_ref_etendu_drivers AND $test_map_etendu_mensuel=$map_ref_etendu_monthly,'OK','ECHEC')
UNION ALL
SELECT 3, 'QUEENS_RESTAURE', $test_map_retour_chauffeurs, $test_map_retour_mensuel,
 $map_ref_queens_drivers, $map_ref_queens_monthly, IFF($test_map_retour_chauffeurs=$map_ref_queens_drivers AND $test_map_retour_mensuel=$map_ref_queens_monthly,'OK','ECHEC')
ORDER BY ordre;
