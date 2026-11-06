-- Test A16 avant purge. Exécuter le fichier entier dans une seule feuille.
-- Le tableau final rassemble les trois étapes : pas besoin de chercher les onglets.
-- On ajoute puis retire uniquement l’entrée de test ; aucune politique modifiée.
USE SECONDARY ROLES NONE;
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
 161 AS chauffeurs_attendus, 365 AS lignes_attendues,
 IFF($test_map_avant_chauffeurs=161 AND $test_map_avant_mensuel=365,'OK','ECHEC') AS statut
UNION ALL
SELECT 2, 'QUEENS_PLUS_BRONX', $test_map_etendu_chauffeurs, $test_map_etendu_mensuel,
 283, 655, IFF($test_map_etendu_chauffeurs=283 AND $test_map_etendu_mensuel=655,'OK','ECHEC')
UNION ALL
SELECT 3, 'QUEENS_RESTAURE', $test_map_retour_chauffeurs, $test_map_retour_mensuel,
 161, 365, IFF($test_map_retour_chauffeurs=161 AND $test_map_retour_mensuel=365,'OK','ECHEC')
ORDER BY ordre;
