-- Fiche rejouable : descriptions et tags ; aucune recréation de table.
-- Les attributs professionnels sans valeur de tag adaptée restent inventoriés.
-- Couverture incomplète du tag DONNEE_PERSONNELLE : voir docs/VEILLE.md et README.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
COMMENT ON TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY IS 'Une ligne par mois, chauffeur et dépôt ; services dédoublonnés depuis STAGING.STG_RH__DRIVER_SHIFTS et identité jointe depuis DIM_DRIVER. Responsable : équipe data Hudson Cab Europe ; reconstruction quotidienne prévue après qualité.';

COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.activity_month IS 'Donnée personnelle. Premier jour du mois auquel l’activité du chauffeur est rattachée. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.driver_id IS 'Donnée personnelle. Identifiant interne du chauffeur ; l’agrégation par chauffeur reste personnelle.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.driver_name IS 'Donnée personnelle. Prénom et nom concaténés depuis DIM_DRIVER ; doit être masqué pour ANALYSTE.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.depot IS 'Donnée personnelle. Dépôt de réalisation des services ; peut différer du rattachement actuel. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.nb_shifts IS 'Donnée personnelle. Nombre de services après dédoublonnage, par mois, chauffeur et dépôt. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.hours_worked IS 'Donnée personnelle. Somme mensuelle des heures travaillées, arrondie à une décimale. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.trips_count IS 'Donnée personnelle. Somme mensuelle des courses effectuées par le chauffeur dans ce dépôt. Inventoriée ; valeur de tag adaptée absente du contrat.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.revenue_usd IS 'Donnée personnelle. Somme mensuelle des recettes du chauffeur en dollars, arrondie à deux décimales. Inventoriée ; valeur de tag adaptée absente du contrat.';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat ; justification juridique par finalité à confirmer';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';

SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'MARTS' AND table_name = 'MART_DRIVER_MONTHLY' ORDER BY ordinal_position;
SELECT column_name, tag_name, tag_value FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'table'));
