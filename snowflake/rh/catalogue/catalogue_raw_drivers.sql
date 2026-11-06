-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Classification complète : extension donnee_professionnelle/activite, voir docs/DECISIONS.md.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
COMMENT ON TABLE NYC_TAXI.RAW.DRIVERS IS 'Une ligne par chauffeur issue de drivers.csv, données RH et traçabilité conservées avant nettoyage. Responsable : RH Hudson Cab Europe ; ingestion à chaque livraison RH, purge quotidienne prévue.';

COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.driver_id IS 'Donnée personnelle. Identifiant interne du chauffeur ; permet les jointures sans afficher son nom.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.first_name IS 'Donnée personnelle. Prénom du chauffeur transmis par les RH.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.last_name IS 'Donnée personnelle. Nom de famille du chauffeur transmis par les RH.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.email IS 'Donnée personnelle. Adresse de contact du chauffeur ; ne pas publier de valeur dans les preuves.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.phone IS 'Donnée personnelle. Numéro de téléphone de contact du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.birth_date IS 'Donnée personnelle. Date de naissance complète ; ANALYSTE ne doit obtenir que l’année.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.tlc_license_number IS 'Donnée personnelle. Numéro officiel de licence TLC du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.depot IS 'Donnée personnelle. Dépôt de rattachement du chauffeur ; attribut professionnel et clé du filtrage. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.hire_date IS 'Donnée personnelle. Date de début de contrat ; intervient dans l’ancienneté. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.end_date IS 'Donnée personnelle. Date de fin de contrat ; NULL signifie en poste ; déclenche le délai de purge. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._source_file IS 'Métadonnée de traçabilité : nom du fichier chargé, sans identité dans le nom.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._loaded_at IS 'Métadonnée de traçabilité : date et heure du chargement Snowflake.';

ALTER TABLE NYC_TAXI.RAW.DRIVERS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat ; justification juridique par finalité à confirmer';

ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN first_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN last_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN email SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN phone SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN birth_date SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN tlc_license_number SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN depot SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN hire_date SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN end_date SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'RAW' AND table_name = 'DRIVERS' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVERS', 'table'));
