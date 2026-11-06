-- Règle bloquante : nombre de services RAW sans chauffeur connu.
-- Seuil contractuel : 50 ; au-delà, enregistrer ALERTE puis arrêter la chaîne.
SELECT COUNT(*) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
WHERE NOT EXISTS (
 SELECT 1 FROM NYC_TAXI.RAW.DRIVERS d WHERE d.driver_id = s.driver_id
);
