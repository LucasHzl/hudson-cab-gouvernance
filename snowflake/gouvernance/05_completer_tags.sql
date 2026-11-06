-- MIGRATION DE CLASSIFICATION — décision projet du 6 novembre 2026.
-- Exécuter entier, hors tâche active. Ne crée ni accès ni tâche, ne relance rien.
-- 1. Masques directs en place avant retrait des anciens liens tag/masque.
-- 2. Extension aux catégories professionnelle et activité.
-- 3. Fiches rejouées, 39 colonnes personnelles classées ; aucune valeur RH affichée.
-- Après : tests/12_couverture_tags.sql puis tests/10_recette_complete.sql.
-- Documents de référence initiaux inchangés ; dérogation expliquée dans DECISIONS.md.
-- Implémenter les attentes de docs/ACCES.md, écrites et commitées avant ce fichier.
-- Préconditions : socle 01, rôles 02, catalogue et migration birth_year exécutés.
-- Rejouable : création conditionnelle, ALTER SET BODY, attaches directes FORCE.
-- Le tag classe ; la politique textuelle lit sa valeur via SYSTEM$GET_TAG_ON_CURRENT_COLUMN.
-- On ne recrée ni les tables, ni les tags, ni une politique déjà attachée.
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

-- A. Masquage piloté par la nature du tag pour les colonnes textuelles.
-- Valeur de secours fermée : jamais laisser val en clair dans le corps initial.
CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL
 AS (val VARCHAR) RETURNS VARCHAR -> '[MASQUE]';
ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL SET BODY ->
 CASE
  WHEN val IS NULL THEN NULL
  WHEN CURRENT_ROLE() IN ('TRANSFORMER','RH_PAIE') THEN val
  WHEN CURRENT_ROLE() IN ('ANALYSTE','RESP_DEPOT_QUEENS','RESP_DEPOT_BRONX')
   AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN('NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE') = 'identifiant_interne'
   THEN val
  WHEN CURRENT_ROLE() IN ('RESP_DEPOT_QUEENS','RESP_DEPOT_BRONX')
   AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN('NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE') IN ('nom','telephone')
   THEN val
  ELSE '[MASQUE]'
 END;

-- Date complète : uniquement paie et pipeline.
CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE
 AS (val DATE) RETURNS DATE -> NULL;
ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE SET BODY ->
 CASE WHEN CURRENT_ROLE() IN ('TRANSFORMER','RH_PAIE') THEN val ELSE NULL END;

-- Année de naissance et mesures numériques : paie, analyste et pipeline.
CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE
 AS (val NUMBER) RETURNS NUMBER -> NULL;
ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE SET BODY ->
 CASE WHEN CURRENT_ROLE() IN ('TRANSFORMER','RH_PAIE','ANALYSTE') THEN val ELSE NULL END;

-- B. Politiques directes pour les attributs professionnels et d’activité.

-- Politiques adaptées à la matrice métier, indépendantes de la classification.
CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_DATE_ACTIVITE
 AS (val DATE) RETURNS DATE -> NULL;
ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_ACTIVITE SET BODY ->
 CASE WHEN CURRENT_ROLE() IN ('TRANSFORMER','RH_PAIE','ANALYSTE') THEN val ELSE NULL END;

CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_FLOAT_ANALYSE
 AS (val FLOAT) RETURNS FLOAT -> NULL;
ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_FLOAT_ANALYSE SET BODY ->
 CASE WHEN CURRENT_ROLE() IN ('TRANSFORMER','RH_PAIE','ANALYSTE') THEN val ELSE NULL END;

CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_BOOL_ANALYSE
 AS (val BOOLEAN) RETURNS BOOLEAN -> NULL;
ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_BOOL_ANALYSE SET BODY ->
 CASE WHEN CURRENT_ROLE() IN ('TRANSFORMER','RH_PAIE','ANALYSTE') THEN val ELSE NULL END;

ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN hire_date SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN end_date SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN hire_date SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN end_date SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN shift_date SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_ACTIVITE FORCE;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN activity_month SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_ACTIVITE FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN start_hour SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN trips_count SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN nb_shifts SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN trips_count SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN hours_worked SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_FLOAT_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN revenue_usd SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_FLOAT_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN tenure_years SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_FLOAT_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN hours_worked SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_FLOAT_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN revenue_usd SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_FLOAT_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN is_active SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_BOOL_ANALYSE FORCE;


-- C. Attaches directes des identifiants, coordonnées et naissance.
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN driver_id SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN first_name SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN last_name SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN email SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN phone SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN birth_date SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN tlc_license_number SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN shift_id SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN driver_id SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN driver_id SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN first_name SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN last_name SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN email SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN phone SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_date SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN tlc_license_number SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_year SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE FORCE;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_id SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_name SET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL FORCE;

-- Retirer les anciens liens automatiques tag/masque seulement après les attaches
-- directes. Ainsi, taguer DEPOT ne tente pas de masquer la clé de la RAP.
-- La garde rend le script rejouable sur un compte neuf ou déjà migré.
EXECUTE IMMEDIATE $$
DECLARE nb NUMBER;
BEGIN
 SELECT COUNT(*) INTO :nb
 FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE', REF_ENTITY_DOMAIN => 'TAG'))
 WHERE policy_kind='MASKING_POLICY' AND policy_db='NYC_TAXI'
   AND policy_schema='GOUVERNANCE' AND policy_name='MASK_TEXTE_PERSONNEL';
 IF (nb > 0) THEN
  ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE
   UNSET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE_PERSONNEL;
 END IF;
 RETURN 'Masquage direct en place ; lien automatique MASK_TEXTE_PERSONNEL retiré si présent';
END;
$$;
EXECUTE IMMEDIATE $$
DECLARE nb NUMBER;
BEGIN
 SELECT COUNT(*) INTO :nb
 FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE', REF_ENTITY_DOMAIN => 'TAG'))
 WHERE policy_kind='MASKING_POLICY' AND policy_db='NYC_TAXI'
   AND policy_schema='GOUVERNANCE' AND policy_name='MASK_DATE_PRIVEE';
 IF (nb > 0) THEN
  ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE
   UNSET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE_PRIVEE;
 END IF;
 RETURN 'Masquage direct en place ; lien automatique MASK_DATE_PRIVEE retiré si présent';
END;
$$;
EXECUTE IMMEDIATE $$
DECLARE nb NUMBER;
BEGIN
 SELECT COUNT(*) INTO :nb
 FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE', REF_ENTITY_DOMAIN => 'TAG'))
 WHERE policy_kind='MASKING_POLICY' AND policy_db='NYC_TAXI'
   AND policy_schema='GOUVERNANCE' AND policy_name='MASK_NOMBRE_ANALYSE';
 IF (nb > 0) THEN
  ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE
   UNSET MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_NOMBRE_ANALYSE;
 END IF;
 RETURN 'Masquage direct en place ; lien automatique MASK_NOMBRE_ANALYSE retiré si présent';
END;
$$;

-- DEPOT reste lisible dans son périmètre et protégé par RAP_DEPOT.
-- Il porte sa classification mais ne reçoit aucune politique de masquage.
SHOW MASKING POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
SELECT policy_name, policy_kind, ref_entity_name, ref_column_name, tag_name, policy_status
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
 REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE'));

USE ROLE GOUVERNANCE;
ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE SET ALLOWED_VALUES 'nom', 'email', 'telephone', 'date_naissance', 'identifiant_officiel', 'identifiant_interne', 'donnee_professionnelle', 'activite';

-- Fiche : catalogue_raw_drivers.sql
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

-- Fiche : catalogue_raw_driver_shifts.sql
-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Classification complète : extension donnee_professionnelle/activite, voir docs/DECISIONS.md.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
COMMENT ON TABLE NYC_TAXI.RAW.DRIVER_SHIFTS IS 'Une ligne source par service issue de driver_shifts.csv, doublons éventuels conservés pour contrôle. Responsable : RH Hudson Cab Europe ; ingestion à chaque livraison, purge quotidienne prévue.';

COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.shift_id IS 'Donnée personnelle. Identifiant interne du service ; relié au chauffeur, utilisé pour le dédoublonnage.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.driver_id IS 'Donnée personnelle. Identifiant interne du chauffeur ayant réalisé le service.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.shift_date IS 'Donnée personnelle. Date du service du chauffeur ; utilisée pour calculer le mois d’activité. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.depot IS 'Donnée personnelle. Dépôt du service du chauffeur ; utilisé pour regrouper et filtrer l’activité. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.start_hour IS 'Donnée personnelle. Heure de début du service, en heure entière. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.hours_worked IS 'Donnée personnelle. Nombre d’heures travaillées pendant le service ; contrôle de plausibilité à 16 heures. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.trips_count IS 'Donnée personnelle. Nombre de courses effectuées pendant le service du chauffeur. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.revenue_usd IS 'Donnée personnelle. Recette du service du chauffeur, en dollars américains. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS._source_file IS 'Métadonnée de traçabilité : nom du fichier chargé, sans identité dans le nom.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS._loaded_at IS 'Métadonnée de traçabilité : date et heure du chargement Snowflake.';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat ; justification juridique par finalité à confirmer';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN shift_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN shift_date SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN depot SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN start_hour SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN hours_worked SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN trips_count SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN revenue_usd SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'RAW' AND table_name = 'DRIVER_SHIFTS' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVER_SHIFTS', 'table'));

-- Fiche : catalogue_dim_driver.sql
-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Classification complète : extension donnee_professionnelle/activite, voir docs/DECISIONS.md.
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
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.depot IS 'Donnée personnelle. Dépôt de rattachement du chauffeur ; attribut professionnel et clé du filtrage. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.hire_date IS 'Donnée personnelle. Date de début de contrat ; intervient dans l’ancienneté. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.end_date IS 'Donnée personnelle. Date de fin de contrat ; NULL signifie en poste ; déclenche le délai de purge. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.is_active IS 'Donnée personnelle. Vrai si end_date est NULL ; statut professionnel calculé. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tenure_years IS 'Donnée personnelle. Ancienneté en années approximatives, jours divisés par 365,25 et arrondis à une décimale. Classification : catégorie complémentaire documentée.';

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

ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN depot SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN hire_date SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN end_date SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN is_active SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN tenure_years SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'MARTS' AND table_name = 'DIM_DRIVER' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER', 'table'));

-- Colonne ajoutée par rh/01_annee_naissance.sql ; exécuter cette migration avant
-- de rejouer la fiche complète sur une installation déjà existante.
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.birth_year IS
  'Donnée personnelle. Année de naissance calculée ; ne donne ni le mois ni le jour à ANALYSTE.';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_year
  SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';

-- Fiche : catalogue_mart_driver_monthly.sql
-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Classification complète : extension donnee_professionnelle/activite, voir docs/DECISIONS.md.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
COMMENT ON TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY IS 'Une ligne par mois, chauffeur et dépôt ; services dédoublonnés depuis STAGING.STG_RH__DRIVER_SHIFTS et identité jointe depuis DIM_DRIVER. Responsable : équipe data Hudson Cab Europe ; reconstruction quotidienne prévue après qualité.';

COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.activity_month IS 'Donnée personnelle. Premier jour du mois auquel l’activité du chauffeur est rattachée. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.driver_id IS 'Donnée personnelle. Identifiant interne du chauffeur ; l’agrégation par chauffeur reste personnelle.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.driver_name IS 'Donnée personnelle. Prénom et nom concaténés depuis DIM_DRIVER ; doit être masqué pour ANALYSTE.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.depot IS 'Donnée personnelle. Dépôt de réalisation des services ; peut différer du rattachement actuel. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.nb_shifts IS 'Donnée personnelle. Nombre de services après dédoublonnage, par mois, chauffeur et dépôt. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.hours_worked IS 'Donnée personnelle. Somme mensuelle des heures travaillées, arrondie à une décimale. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.trips_count IS 'Donnée personnelle. Somme mensuelle des courses effectuées par le chauffeur dans ce dépôt. Classification : catégorie complémentaire documentée.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.revenue_usd IS 'Donnée personnelle. Somme mensuelle des recettes du chauffeur en dollars, arrondie à deux décimales. Classification : catégorie complémentaire documentée.';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat ; justification juridique par finalité à confirmer';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN activity_month SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN depot SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'donnee_professionnelle';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN nb_shifts SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN hours_worked SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN trips_count SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN revenue_usd SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'activite';
SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'MARTS' AND table_name = 'MART_DRIVER_MONTHLY' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'table'));

SELECT 'Migration de classification terminée ; exécuter les tests 12 puis 10' AS prochaine_etape;
