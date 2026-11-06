-- CONSULTATION PRIVÉE : résultat contenant les comptes Snowflake des lecteurs.
-- Ne pas publier ce résultat ni sa capture dans le dépôt public.
-- Le script seul, dépourvu de valeurs personnelles, est versionnable.
-- Complément nominatif de 06_audit.sql ; même fenêtre de sept jours et latence.
USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
WITH lectures AS (
 SELECT a.query_id, a.query_start_time, a.user_name,
        COALESCE(q.role_name,'[ROLE_EN_ATTENTE]') AS role_name,
        COALESCE(q.query_type,'[TYPE_EN_ATTENTE]') AS query_type,
        o.value:objectName::VARCHAR AS objet,
        c.value:columnName::VARCHAR AS colonne
 FROM (
  SELECT query_id,query_start_time,user_name,base_objects_accessed
  FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
  WHERE query_start_time >= DATEADD(day,-7,CURRENT_TIMESTAMP())
 ) a
 LEFT JOIN (
  SELECT query_id,role_name,query_type
  FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
  WHERE start_time >= DATEADD(day,-7,CURRENT_TIMESTAMP())
 ) q ON q.query_id=a.query_id,
 LATERAL FLATTEN(INPUT => a.base_objects_accessed) o,
 LATERAL FLATTEN(INPUT => o.value:columns, OUTER => TRUE) c
 WHERE o.value:objectName::VARCHAR='NYC_TAXI.MARTS.DIM_DRIVER'
)
SELECT query_start_time,query_id,user_name,role_name,query_type,objet,
       LISTAGG(DISTINCT colonne, ', ') WITHIN GROUP (ORDER BY colonne) AS colonnes_referencees
FROM lectures
GROUP BY query_start_time,query_id,user_name,role_name,query_type,objet
ORDER BY query_start_time DESC;
