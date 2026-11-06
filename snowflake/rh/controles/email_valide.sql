-- Avertissement : un email doit contenir @ ; NULL est également en anomalie.
-- Seuil : zéro. Ce contrôle ne démontre pas la délivrabilité de l’adresse.
SELECT COUNT(*) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS
WHERE email IS NULL OR POSITION('@' IN email) = 0;
