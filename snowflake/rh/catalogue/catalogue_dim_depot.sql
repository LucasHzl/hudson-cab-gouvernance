-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Référentiel sans donnée personnelle : sensibilité et conservation documentées.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
COMMENT ON TABLE NYC_TAXI.MARTS.DIM_DEPOT IS 'Une ligne par garage ; référentiel fourni dans rh/marts/dim_depot.sql, indépendant des fiches chauffeurs. Responsable : équipe data ; valeurs modifiées à l’ouverture ou à la fermeture d’un garage, réinsérées par le pipeline quotidien prévu.';

COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DEPOT.depot IS 'Nom canonique du garage : Bronx, Brooklyn ou Queens ; clé du référentiel.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DEPOT.quartier IS 'Quartier new-yorkais où se situe le garage.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DEPOT.ouvert_en IS 'Année d’ouverture du garage.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DEPOT.nb_places IS 'Capacité du garage en nombre de taxis.';

ALTER TABLE NYC_TAXI.MARTS.DIM_DEPOT SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'interne',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = 'Pendant la vie utile du référentiel ; aucune donnée personnelle';


SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'MARTS' AND table_name = 'DIM_DEPOT' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DEPOT', 'table'));
