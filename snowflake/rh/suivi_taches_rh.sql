-- CAPTURE : quand les trois lignes sont SUCCEEDED, conserver CE tableau,
-- puis le graphe Snowsight de cette exécution. Ce fichier ne lance aucune tâche.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
WITH historique AS (
 SELECT * FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TASK_HISTORY(
  SCHEDULED_TIME_RANGE_START => DATEADD('hour',-4,CURRENT_TIMESTAMP()),
  RESULT_LIMIT => 1000))
 WHERE database_name='NYC_TAXI' AND schema_name='MARTS'
   AND name IN ('T_PURGE','T_QUALITE','T_TABLES') AND state <> 'SCHEDULED'
), dernier AS (
 SELECT graph_run_group_id, attempt_number
 FROM historique WHERE name='T_PURGE'
 QUALIFY ROW_NUMBER() OVER (ORDER BY scheduled_time DESC)=1
), attendues AS (
 SELECT column1 AS ordre,column2 AS tache
 FROM VALUES (1,'T_PURGE'),(2,'T_QUALITE'),(3,'T_TABLES')
)
SELECT a.ordre,a.tache,COALESCE(h.state,'NON_DEMARREE') AS etat,
       h.query_start_time,h.completed_time,h.error_message,
       d.graph_run_group_id
FROM attendues a CROSS JOIN dernier d
LEFT JOIN historique h ON h.name=a.tache
 AND h.graph_run_group_id=d.graph_run_group_id AND h.attempt_number=d.attempt_number
ORDER BY a.ordre;
-- Si vide ou NON_DEMARREE/EXECUTING : attendre quelques dizaines de secondes
-- puis relancer seulement ce fichier. En cas de FAILED, conserver le message.
