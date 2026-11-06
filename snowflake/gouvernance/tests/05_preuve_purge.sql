-- EXÉCUTE réellement la purge, après avoir mémorisé des comptes et un instant.
-- À lancer APRÈS conservation_rh.sql, une fois les tests avant purge terminés.
-- Fichier entier dans une seule feuille/session. Pas de copie persistante des IDs.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
ALTER SESSION SET TIMEZONE = 'Europe/Paris';
SET test_purge_date_limite = DATEADD(year,-5,CURRENT_DATE());
SET test_purge_instant_avant = CURRENT_TIMESTAMP();
SET test_purge_chauffeurs_avant = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS);
SET test_purge_concernes = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < $test_purge_date_limite);
SET test_purge_services_avant = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS);
SET test_purge_services_concernes = (
 SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS
 WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < $test_purge_date_limite));

-- Même bloc atomique que rh/purge_rh.sql. En cas d’échec, rollback et erreur.
EXECUTE IMMEDIATE $$
DECLARE
 date_limite DATE DEFAULT DATEADD(year,-5,CURRENT_DATE());
BEGIN
 BEGIN TRANSACTION;
 -- Supprimer les copies avant la source qui identifie les chauffeurs concernés.
 DELETE FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
 WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < :date_limite);
 DELETE FROM NYC_TAXI.MARTS.DIM_DRIVER
 WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < :date_limite);
 DELETE FROM NYC_TAXI.RAW.DRIVER_SHIFTS
 WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < :date_limite);
 DELETE FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < :date_limite;
 COMMIT;
 RETURN 'Purge complète des quatre tables RH terminée';
EXCEPTION
 WHEN OTHER THEN
  ROLLBACK;
  RAISE;
END;
$$;

-- Comptages seulement : aucune donnée personnelle dans le résultat.
SET test_purge_chauffeurs_apres = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS);
SET test_purge_services_apres = (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS);
SET test_purge_historique = (
 SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS
 AT(TIMESTAMP => $test_purge_instant_avant::TIMESTAMP_TZ));
SET test_purge_raw_expires = (
 SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < $test_purge_date_limite);
SET test_purge_dim_expires = (
 SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE end_date < $test_purge_date_limite);
SET test_purge_services_copies = (
 SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS
 WHERE driver_id IN (
  SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS AT(TIMESTAMP => $test_purge_instant_avant::TIMESTAMP_TZ)
  WHERE end_date < $test_purge_date_limite));
SET test_purge_mensuel_copies = (
 SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
 WHERE driver_id IN (
  SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS AT(TIMESTAMP => $test_purge_instant_avant::TIMESTAMP_TZ)
  WHERE end_date < $test_purge_date_limite));

SELECT 'chauffeurs_apres' AS controle, $test_purge_chauffeurs_apres AS obtenu,
 $test_purge_chauffeurs_avant-$test_purge_concernes AS attendu,
 IFF($test_purge_chauffeurs_apres=$test_purge_chauffeurs_avant-$test_purge_concernes,'OK','ECHEC') AS statut
UNION ALL SELECT 'services_apres',$test_purge_services_apres,$test_purge_services_avant-$test_purge_services_concernes,IFF($test_purge_services_apres=$test_purge_services_avant-$test_purge_services_concernes,'OK','ECHEC')
UNION ALL SELECT 'chauffeurs_avant_via_time_travel',$test_purge_historique,$test_purge_chauffeurs_avant,IFF($test_purge_historique=$test_purge_chauffeurs_avant,'OK','ECHEC')
UNION ALL SELECT 'expires_dans_RAW',$test_purge_raw_expires,0,IFF($test_purge_raw_expires=0,'OK','ECHEC')
UNION ALL SELECT 'expires_dans_DIM',$test_purge_dim_expires,0,IFF($test_purge_dim_expires=0,'OK','ECHEC')
UNION ALL SELECT 'services_de_chauffeurs_purges',$test_purge_services_copies,0,IFF($test_purge_services_copies=0,'OK','ECHEC')
UNION ALL SELECT 'mensuel_de_chauffeurs_purges',$test_purge_mensuel_copies,0,IFF($test_purge_mensuel_copies=0,'OK','ECHEC')
ORDER BY controle;
-- Première exécution attendue au 6 novembre 2026 sur le kit initial :
-- 46 chauffeurs concernés, 354 restants, historique 400 ; zéro service lié aux
-- partants anciens dans ce jeu, donc les 25 951 services restent. Ce zéro ne
-- dispense pas du DELETE des services dans la règle générale.
-- Une seconde exécution reste correcte mais l’état avant sera déjà purgé.
