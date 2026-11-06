-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Les attributs professionnels sans valeur de tag adaptée restent inventoriés.
-- Couverture incomplète du tag DONNEE_PERSONNELLE : voir docs/VEILLE.md et README.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
COMMENT ON TABLE NYC_TAXI.MARTS.DIM_DRIVER IS 'Une ligne par chauffeur depuis RAW.DRIVERS via STAGING.STG_RH__DRIVERS ; identité, rattachement et ancienneté. Responsable : RH Hudson Cab Europe ; reconstruction quotidienne prévue après purge et qualité.';

COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.driver_id IS 'Donnée personnelle. Identifiant interne du chauffeur ; permet les jointures sans afficher son nom.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.first_name IS 'Donnée personnelle. Prénom du chauffeur transmis par les RH.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.last_name IS 'Donnée personnelle. Nom de famille du chauffeur transmis par les RH.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.email IS 'Donnée personnelle. Adresse de contact du chauffeur ; ne pas publier de valeur dans les preuves.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.phone IS 'Donnée personnelle. Numéro de téléphone de contact du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.birth_date IS 'Donnée personnelle. Date de naissance complète ; ANALYSTE ne doit obtenir que l’année.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tlc_license_number IS 'Donnée personnelle. Numéro officiel de licence TLC du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.depot IS 'Donnée personnelle. Dépôt de rattachement du chauffeur ; attribut professionnel et clé du filtrage. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.hire_date IS 'Donnée personnelle. Date de début de contrat ; intervient dans l’ancienneté. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.end_date IS 'Donnée personnelle. Date de fin de contrat ; NULL signifie en poste ; déclenche le délai de purge. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.is_active IS 'Donnée personnelle. Vrai si end_date est NULL ; statut professionnel calculé. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tenure_years IS 'Donnée personnelle. Ancienneté en années approximatives, jours divisés par 365,25 et arrondis à une décimale. Inventoriée ; valeur de tag adaptée absente du contrat.';

ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat ; justification juridique par finalité à confirmer';

ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN first_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN last_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN email SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN phone SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_date SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN tlc_license_number SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'MARTS' AND table_name = 'DIM_DRIVER' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER', 'table'));
