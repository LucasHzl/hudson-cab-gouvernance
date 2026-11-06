-- CAPTURE : résultat agrégé ci-dessous, sans compte utilisateur ni texte SQL.
-- Brief : audit avec ACCOUNTADMIN ; ne donne aucun droit SELECT RH supplémentaire.
-- ACCESS_HISTORY peut avoir jusqu’à 3 h de retard : vide ne prouve pas zéro lecture.
-- JOIN query_id : objets/colonnes viennent de ACCESS_HISTORY, rôle de QUERY_HISTORY.
-- Inclut les lectures des transformations, identifiables par QUERY_TYPE.
-- Un accès à une colonne ne prouve pas une valeur personnelle vue en clair :
-- les masques et filtres dépendent du rôle ; compléter par les tests d’accès.
-- Source : https://docs.snowflake.com/en/sql-reference/account-usage/access_history
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
SELECT role_name AS role_lecteur, query_type AS type_requete, objet,
       COUNT(DISTINCT query_id) AS nb_requetes,
       LISTAGG(DISTINCT colonne, ', ') WITHIN GROUP (ORDER BY colonne) AS colonnes_referencees,
       MIN(query_start_time) AS premiere_lecture,
       MAX(query_start_time) AS derniere_lecture
FROM lectures
GROUP BY role_name,query_type,objet
ORDER BY role_lecteur,type_requete;
