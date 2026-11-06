-- Filtrer les quatre tables RH avec une correspondance rôle/dépôt.
-- Le propriétaire GOUVERNANCE lit le mapping lors de l’évaluation de la politique ;
-- aucun SELECT sur ACCES_DEPOT n’est nécessaire pour les lecteurs métier.
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.ACCES_DEPOT (
 role_name VARCHAR NOT NULL,
 depot VARCHAR NOT NULL
) COMMENT = 'Habilitations RH : une ligne rôle/dépôt ; * autorise tous les dépôts. Aucun utilisateur nommé.';

-- Insérer seulement les règles initiales manquantes. Les extensions du mapping
-- restent présentes lors d’un rejeu : ne pas vider la table.
MERGE INTO NYC_TAXI.GOUVERNANCE.ACCES_DEPOT cible
USING (
 SELECT column1 AS role_name, column2 AS depot FROM VALUES
  ('TRANSFORMER','*'),
  ('RH_PAIE','*'),
  ('ANALYSTE','*'),
  ('RESP_DEPOT_QUEENS','Queens'),
  ('RESP_DEPOT_BRONX','Bronx')
) source
ON cible.role_name = source.role_name AND cible.depot = source.depot
WHEN NOT MATCHED THEN INSERT (role_name,depot) VALUES (source.role_name,source.depot);

CREATE ROW ACCESS POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.RAP_DEPOT
 AS (depot_ligne VARCHAR) RETURNS BOOLEAN -> FALSE;
ALTER ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT SET BODY ->
 EXISTS (
  SELECT 1 FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT a
  WHERE a.role_name = CURRENT_ROLE()
    AND (a.depot = '*' OR a.depot = depot_ligne)
 );

-- Attacher sans retirer une protection existante. Au rejeu, garder notre RAP ;
-- une politique inattendue provoque une erreur explicite, pas un écrasement.

EXECUTE IMMEDIATE $$
DECLARE
 nb NUMBER;
 attendue NUMBER;
 conflit EXCEPTION (-20001, 'Politique de lignes inattendue sur RAW.DRIVERS : inspecter avant modification.');
BEGIN
 SELECT COUNT(*), COALESCE(COUNT_IF(policy_db = 'NYC_TAXI'
    AND policy_schema = 'GOUVERNANCE' AND policy_name = 'RAP_DEPOT'),0)
 INTO :nb, :attendue
 FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.RAW.DRIVERS', REF_ENTITY_DOMAIN => 'TABLE'))
 WHERE policy_kind = 'ROW_ACCESS_POLICY';
 IF (nb = 0) THEN
  ALTER TABLE NYC_TAXI.RAW.DRIVERS ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);
 ELSEIF (nb <> 1 OR attendue <> 1) THEN
  RAISE conflit;
 END IF;
 RETURN 'RAP_DEPOT en place sur RAW.DRIVERS';
END;
$$;

EXECUTE IMMEDIATE $$
DECLARE
 nb NUMBER;
 attendue NUMBER;
 conflit EXCEPTION (-20001, 'Politique de lignes inattendue sur RAW.DRIVER_SHIFTS : inspecter avant modification.');
BEGIN
 SELECT COUNT(*), COALESCE(COUNT_IF(policy_db = 'NYC_TAXI'
    AND policy_schema = 'GOUVERNANCE' AND policy_name = 'RAP_DEPOT'),0)
 INTO :nb, :attendue
 FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.RAW.DRIVER_SHIFTS', REF_ENTITY_DOMAIN => 'TABLE'))
 WHERE policy_kind = 'ROW_ACCESS_POLICY';
 IF (nb = 0) THEN
  ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);
 ELSEIF (nb <> 1 OR attendue <> 1) THEN
  RAISE conflit;
 END IF;
 RETURN 'RAP_DEPOT en place sur RAW.DRIVER_SHIFTS';
END;
$$;

EXECUTE IMMEDIATE $$
DECLARE
 nb NUMBER;
 attendue NUMBER;
 conflit EXCEPTION (-20001, 'Politique de lignes inattendue sur MARTS.DIM_DRIVER : inspecter avant modification.');
BEGIN
 SELECT COUNT(*), COALESCE(COUNT_IF(policy_db = 'NYC_TAXI'
    AND policy_schema = 'GOUVERNANCE' AND policy_name = 'RAP_DEPOT'),0)
 INTO :nb, :attendue
 FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE'))
 WHERE policy_kind = 'ROW_ACCESS_POLICY';
 IF (nb = 0) THEN
  ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);
 ELSEIF (nb <> 1 OR attendue <> 1) THEN
  RAISE conflit;
 END IF;
 RETURN 'RAP_DEPOT en place sur MARTS.DIM_DRIVER';
END;
$$;

EXECUTE IMMEDIATE $$
DECLARE
 nb NUMBER;
 attendue NUMBER;
 conflit EXCEPTION (-20001, 'Politique de lignes inattendue sur MARTS.MART_DRIVER_MONTHLY : inspecter avant modification.');
BEGIN
 SELECT COUNT(*), COALESCE(COUNT_IF(policy_db = 'NYC_TAXI'
    AND policy_schema = 'GOUVERNANCE' AND policy_name = 'RAP_DEPOT'),0)
 INTO :nb, :attendue
 FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', REF_ENTITY_DOMAIN => 'TABLE'))
 WHERE policy_kind = 'ROW_ACCESS_POLICY';
 IF (nb = 0) THEN
  ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);
 ELSEIF (nb <> 1 OR attendue <> 1) THEN
  RAISE conflit;
 END IF;
 RETURN 'RAP_DEPOT en place sur MARTS.MART_DRIVER_MONTHLY';
END;
$$;

-- Aucun rôle admin dans le mapping : zéro ligne RH sous ACCOUNTADMIN/SYSADMIN.
-- Les métiers n’ont aucun privilège RAW/STAGING malgré leurs entrées de mapping.
SELECT role_name, depot FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT ORDER BY role_name,depot;
SHOW ROW ACCESS POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
