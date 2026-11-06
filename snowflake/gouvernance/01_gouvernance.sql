-- Initialiser la gouvernance après l’installation et les transformations RH.
-- Rejouable : création conditionnelle, droits réaccordés sans recréer les objets.
-- Aucun droit SELECT sur RAW, STAGING ou MARTS accordé à GOUVERNANCE.
-- Références : contrat sections 1 et 3, guide jour 1 étape 10.

USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;

-- A. Créer le rôle et l’attribuer à l’utilisateur courant pour les exercices.
-- Aucun privilège métier n’est attribué directement à cet utilisateur.
SET utilisateur_courant = CURRENT_USER();
CREATE ROLE IF NOT EXISTS GOUVERNANCE
  COMMENT = 'Administration des règles RH sans lecture des données du personnel';
GRANT ROLE GOUVERNANCE TO USER IDENTIFIER($utilisateur_courant);
GRANT USAGE ON DATABASE NYC_TAXI TO ROLE GOUVERNANCE;
GRANT USAGE ON WAREHOUSE NYC_TAXI_WH TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.RAW TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.MARTS TO ROLE GOUVERNANCE;

-- USAGE permet de désigner les objets ; il n’accorde pas leur lecture.
CREATE SCHEMA IF NOT EXISTS NYC_TAXI.GOUVERNANCE
  COMMENT = 'Catalogue, règles d’accès et suivi de qualité du domaine RH';
GRANT OWNERSHIP ON SCHEMA NYC_TAXI.GOUVERNANCE
  TO ROLE GOUVERNANCE COPY CURRENT GRANTS;

-- Ces droits permettent d’attacher les futures politiques aux tables d’un autre rôle.
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE GOUVERNANCE;
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE GOUVERNANCE;

-- B. Le rôle propriétaire crée les métadonnées et la table de résultats.
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.SENSIBILITE
  ALLOWED_VALUES 'public', 'interne', 'confidentiel'
  COMMENT = 'Niveau de sensibilité de la table';
CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE
  ALLOWED_VALUES 'nom', 'email', 'telephone', 'date_naissance', 'identifiant_officiel', 'identifiant_interne', 'donnee_professionnelle', 'activite'
  COMMENT = 'Nature personnelle : six catégories initiales et extension professionnelle/activité documentée dans DECISIONS.md';
-- Réappliquer l’extension sur une installation existante.
ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE SET ALLOWED_VALUES 'nom', 'email', 'telephone', 'date_naissance', 'identifiant_officiel', 'identifiant_interne', 'donnee_professionnelle', 'activite';
CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION
  COMMENT = 'Durée et événement de départ du délai ; le tag décrit, la purge exécute';

CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS (
    regle VARCHAR,
    mesure_le TIMESTAMP_NTZ,
    nb_anomalies NUMBER(18,0),
    seuil NUMBER(18,2),
    statut VARCHAR
) COMMENT = 'Historique des contrôles : une ligne par règle et exécution ; sans valeurs personnelles en anomalie';

-- C. TRANSFORMER pourra cataloguer ses tables et écrire les résultats de qualité.
GRANT USAGE ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.SENSIBILITE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION TO ROLE TRANSFORMER;
GRANT INSERT, SELECT ON TABLE NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS TO ROLE TRANSFORMER;
GRANT CREATE VIEW ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;

-- D. Vérifications : inspecter les droits, puis trois tags attendus.
SHOW GRANTS TO ROLE GOUVERNANCE;
SHOW GRANTS TO ROLE TRANSFORMER;
SHOW TAGS IN SCHEMA NYC_TAXI.GOUVERNANCE;
