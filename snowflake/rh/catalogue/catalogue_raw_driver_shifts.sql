-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Les attributs professionnels sans valeur de tag adaptée restent inventoriés.
-- Couverture incomplète du tag DONNEE_PERSONNELLE : voir docs/VEILLE.md et README.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
COMMENT ON TABLE NYC_TAXI.RAW.DRIVER_SHIFTS IS 'Une ligne source par service issue de driver_shifts.csv, doublons éventuels conservés pour contrôle. Responsable : RH Hudson Cab Europe ; ingestion à chaque livraison, purge quotidienne prévue.';

COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.shift_id IS 'Donnée personnelle. Identifiant interne du service ; relié au chauffeur, utilisé pour le dédoublonnage.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.driver_id IS 'Donnée personnelle. Identifiant interne du chauffeur ayant réalisé le service.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.shift_date IS 'Donnée personnelle. Date du service du chauffeur ; utilisée pour calculer le mois d’activité. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.depot IS 'Donnée personnelle. Dépôt du service du chauffeur ; utilisé pour regrouper et filtrer l’activité. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.start_hour IS 'Donnée personnelle. Heure de début du service, en heure entière. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.hours_worked IS 'Donnée personnelle. Nombre d’heures travaillées pendant le service ; contrôle de plausibilité à 16 heures. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.trips_count IS 'Donnée personnelle. Nombre de courses effectuées pendant le service du chauffeur. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.revenue_usd IS 'Donnée personnelle. Recette du service du chauffeur, en dollars américains. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS._source_file IS 'Métadonnée de traçabilité : nom du fichier chargé, sans identité dans le nom.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS._loaded_at IS 'Métadonnée de traçabilité : date et heure du chargement Snowflake.';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat ; justification juridique par finalité à confirmer';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN shift_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';

SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'RAW' AND table_name = 'DRIVER_SHIFTS' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVER_SHIFTS', 'table'));
