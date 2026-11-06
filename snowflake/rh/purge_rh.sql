-- R1 : supprimer les chauffeurs partis depuis PLUS de cinq ans et leurs copies.
-- Rejouable : après une purge réussie, aucune ligne déjà supprimée ne réapparaît.
-- Avant la première exécution, utiliser tests/05_preuve_purge.sql pour les preuves.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
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

SELECT COUNT(*) AS chauffeurs_expires_restants
FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year,-5,CURRENT_DATE());
-- Attendu : zéro. Les vues STAGING reflètent RAW ; aucun stockage à purger dedans.
