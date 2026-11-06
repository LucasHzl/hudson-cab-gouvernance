-- AVANT EXÉCUTION : prévoir deux preuves, historique SUCCEEDED puis graphe.
-- Ce fichier active aussi l’horaire quotidien ; suspendre la racine à la fin du brief.
-- Le retour « scheduled » signifie demandé, pas terminé. Ne pas relancer le graphe
-- pour rafraîchir son résultat : exécuter suivi_taches_rh.sql à la place.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('NYC_TAXI.MARTS.T_PURGE');
EXECUTE TASK NYC_TAXI.MARTS.T_PURGE;
