-- Adapter la table existante sans la recréer : les politiques et tags restent.
-- Séparer année de naissance et date complète évite de renvoyer une fausse date.
-- À exécuter après le catalogue et avant les politiques.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER ADD COLUMN IF NOT EXISTS birth_year NUMBER(4,0);
UPDATE NYC_TAXI.MARTS.DIM_DRIVER SET birth_year = YEAR(birth_date);
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.birth_year IS
  'Donnée personnelle. Année de naissance calculée depuis birth_date ; seule précision de naissance accessible à ANALYSTE, date complète masquée.';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_year
  SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
SELECT COUNT(*) AS chauffeurs,
       COUNT_IF(birth_year IS DISTINCT FROM YEAR(birth_date)) AS annees_incoherentes
FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- Attendu avant purge : 400 et 0. Pas de valeur personnelle dans ce résultat.
