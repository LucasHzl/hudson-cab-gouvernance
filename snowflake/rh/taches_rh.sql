-- CRÉATION uniquement : les tâches restent suspendues à la fin de ce fichier.
-- Après création : inspecter le graphe ; pour lancer, utiliser lancer_taches_rh.sql.
-- Rejouer uniquement hors d’une exécution active : suspendre le graphe n’annule
-- pas forcément une exécution déjà en cours. Aucun objet de données n’est recréé.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

CREATE TASK IF NOT EXISTS NYC_TAXI.MARTS.T_PURGE
 WAREHOUSE = NYC_TAXI_WH
 SCHEDULE = 'USING CRON 0 5 * * * Europe/Paris'
 AS SELECT 1;
ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
CREATE TASK IF NOT EXISTS NYC_TAXI.MARTS.T_QUALITE
 WAREHOUSE = NYC_TAXI_WH
 AFTER NYC_TAXI.MARTS.T_PURGE
 AS SELECT 1;
CREATE TASK IF NOT EXISTS NYC_TAXI.MARTS.T_TABLES
 WAREHOUSE = NYC_TAXI_WH
 AFTER NYC_TAXI.MARTS.T_QUALITE
 AS SELECT 1;
ALTER TASK NYC_TAXI.MARTS.T_QUALITE SUSPEND;
ALTER TASK NYC_TAXI.MARTS.T_TABLES SUSPEND;

ALTER TASK NYC_TAXI.MARTS.T_PURGE SET SCHEDULE = 'USING CRON 0 5 * * * Europe/Paris';
ALTER TASK NYC_TAXI.MARTS.T_PURGE SET WAREHOUSE = NYC_TAXI_WH;
ALTER TASK NYC_TAXI.MARTS.T_PURGE SET TIMEZONE = 'Europe/Paris';
ALTER TASK NYC_TAXI.MARTS.T_QUALITE SET WAREHOUSE = NYC_TAXI_WH;
ALTER TASK NYC_TAXI.MARTS.T_QUALITE SET TIMEZONE = 'Europe/Paris';
ALTER TASK NYC_TAXI.MARTS.T_TABLES SET WAREHOUSE = NYC_TAXI_WH;
ALTER TASK NYC_TAXI.MARTS.T_TABLES SET TIMEZONE = 'Europe/Paris';

-- Bloc identique à purge_rh.sql.
ALTER TASK NYC_TAXI.MARTS.T_PURGE MODIFY AS
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

-- Bloc identique à qualite_rh.sql : commit des mesures AVANT le blocage.
ALTER TASK NYC_TAXI.MARTS.T_QUALITE MODIFY AS
EXECUTE IMMEDIATE $$
DECLARE
 nb_orphelins NUMBER;
 seuil_rattachement NUMBER DEFAULT 50;
 mesure TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
 blocage EXCEPTION (-20003, 'Qualité bloquante : service_rattache dépasse le seuil ; aucune reconstruction autorisée.');
BEGIN
 SELECT COUNT(*) INTO :nb_orphelins
 FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
 WHERE NOT EXISTS (SELECT 1 FROM NYC_TAXI.RAW.DRIVERS d WHERE d.driver_id=s.driver_id);

 -- Journaliser les trois résultats et les valider AVANT toute erreur bloquante.
 -- Le bloc intérieur annule l’écriture si elle échoue, sans effacer une mesure
 -- correctement validée lorsque le blocage fonctionnel est levé ensuite.
 BEGIN
  BEGIN TRANSACTION;
  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle,mesure_le,nb_anomalies,seuil,statut)
  SELECT 'licence_unique', :mesure, nb_anomalies, 0,
         IFF(nb_anomalies <= 0,'OK','ALERTE')
  FROM (
   SELECT COUNT(*)-COUNT(DISTINCT tlc_license_number) AS nb_anomalies
   FROM NYC_TAXI.RAW.DRIVERS
  )
  UNION ALL
  SELECT 'email_valide', :mesure, nb_anomalies, 0,
         IFF(nb_anomalies <= 0,'OK','ALERTE')
  FROM (
   SELECT COUNT(*) AS nb_anomalies FROM NYC_TAXI.RAW.DRIVERS
   WHERE email IS NULL OR POSITION('@' IN email)=0
  )
  UNION ALL
  SELECT 'service_rattache', :mesure, :nb_orphelins, :seuil_rattachement,
         IFF(:nb_orphelins <= :seuil_rattachement,'OK','ALERTE');
  COMMIT;
 EXCEPTION
  WHEN OTHER THEN
   ROLLBACK;
   RAISE;
 END;

 IF (nb_orphelins > seuil_rattachement) THEN
  RAISE blocage;
 END IF;
 RETURN 'Trois règles enregistrées ; pas de dépassement bloquant';
END;
$$;

-- Les trois INSERT OVERWRITE sont repris exactement des fichiers métier.
ALTER TASK NYC_TAXI.MARTS.T_TABLES MODIFY AS
EXECUTE IMMEDIATE $$
BEGIN
 BEGIN TRANSACTION;
INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DEPOT (depot, quartier, ouvert_en, nb_places) VALUES
    ('Bronx',    'Hunts Point',       2009, 140),
    ('Brooklyn', 'East New York',     2011, 120),
    ('Queens',   'Long Island City',  2008, 180);
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
 COMMIT;
 RETURN 'Trois tables métier reconstruites sans recréation';
EXCEPTION
 WHEN OTHER THEN
  ROLLBACK;
  RAISE;
END;
$$;

SHOW TASKS IN SCHEMA NYC_TAXI.MARTS;
SELECT "name" AS tache, "owner" AS role_proprietaire,
       "state" AS etat, "schedule" AS horaire, "predecessors" AS dependances
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" IN ('T_PURGE','T_QUALITE','T_TABLES') ORDER BY "name";
-- Attendu : trois tâches, propriétaire TRANSFORMER, état suspended.
