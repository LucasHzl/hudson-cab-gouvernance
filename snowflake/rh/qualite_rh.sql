-- CAPTURE : prendre le tableau final des TROIS règles immédiatement après exécution.
-- Les ALERTE non bloquantes sont des résultats attendus, pas des erreurs SQL.
-- TRANSFORMER lit RAW en clair et ajoute les mesures ; aucune donnée nominative
-- n’est écrite dans QUALITE_RESULTATS. Rejouer ajoute une nouvelle mesure par règle.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
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

-- Dernière mesure complète : trois lignes avec le même instant.
SELECT regle, mesure_le, nb_anomalies, seuil, statut
FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
WHERE mesure_le = (SELECT MAX(mesure_le) FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS)
ORDER BY regle;
