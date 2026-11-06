# Accès — carte des droits et cahier de tests

Mis à jour le 6 novembre 2026. **Résultats attendus écrits avant les politiques. Démo agrégée de quatre rôles vérifiée sur captures ; cahier complet encore en cours.** Exécution des politiques 03/04 corrigées confirmée par Lucas et comportements de la démo observés ; rejeu et autres tests à vérifier. SQL de tests : `snowflake/gouvernance/tests/01_tests_acces.sql`. Exécuter les blocs séparément, surtout les refus attendus.

## 1. Propriété et droits

Propriétés ci-dessous prévues par les scripts ; confirmer avec SHOW GRANTS. Le socle 01 a été exécuté selon le retour de Lucas ; script 02 exécuté selon le retour de Lucas.

| Objet | Propriétaire prévu |
|---|---|
| RAW, vues STAGING, tables MARTS et futures tâches | TRANSFORMER pour les objets qu’il crée |
| Schéma GOUVERNANCE, tags et QUALITE_RESULTATS | GOUVERNANCE |
| Futures politiques et table ACCES_DEPOT | GOUVERNANCE |
| V_CATALOGUE | TRANSFORMER |

| Rôle | Droits et objets autorisés | Exclus |
|---|---|---|
| RH_PAIE, RESP_DEPOT_QUEENS, RESP_DEPOT_BRONX | USAGE base/warehouse/MARTS/GOUVERNANCE ; SELECT sur DIM_DRIVER, MART_DRIVER_MONTHLY et DIM_DEPOT ; vues actuelles/futures du catalogue | RAW, STAGING, écriture métier |
| ANALYSTE | Mêmes USAGE ; SELECT sur toutes les tables et vues actuelles/futures de MARTS ; vues actuelles/futures de GOUVERNANCE | RAW, STAGING, écriture métier |
| GOUVERNANCE | USAGE base/warehouse/RAW/MARTS ; propriété du schéma GOUVERNANCE ; APPLY MASKING POLICY et APPLY ROW ACCESS POLICY sur le compte | SELECT sur le personnel |
| TRANSFORMER | Droits du script 00 ; USAGE et CREATE VIEW sur GOUVERNANCE, APPLY sur les trois tags, INSERT/SELECT sur QUALITE_RESULTATS | Aucun droit de gestion métier supplémentaire prévu |

Un USAGE permet d’utiliser un contenant ; SELECT permet d’en lire les objets autorisés. Aucun rôle métier n’hérite de TRANSFORMER. Les rôles métier sont attribués uniquement à l’utilisateur courant pour les tests ; ouverture à d’autres personnes après validation.

Limites de séparation des fonctions : TRANSFORMER possède les tables et peut modifier certaines protections ; GOUVERNANCE peut modifier les règles ; ACCOUNTADMIN peut changer des habilitations. Les tests prouvent le comportement des rôles actifs à un instant donné, pas l’impossibilité pour un administrateur de reconfigurer le système. Auditer les changements et limiter l’usage de ces rôles.

## 2. Conventions de masquage prévues

- Texte nominatif ou coordonnée : `[MASQUE]` ; NULL source reste NULL.
- Date, nombre et booléen : NULL quand masqués.
- `driver_id` : visible aux quatre rôles métier, exception explicite du contrat.
- `depot` : visible dans le périmètre autorisé pour expliquer et tester le filtrage. DIM_DEPOT reste lisible sans filtre.
- `birth_date` : date complète pour RH_PAIE et TRANSFORMER ; NULL pour les autres lecteurs métier.
- `birth_year` : colonne ajoutée, calculée et taguée `date_naissance` ; visible pour ANALYSTE, RH_PAIE et TRANSFORMER. Elle évite de présenter un faux 1er janvier comme date de naissance.
- Attributs professionnels sans tag adapté : maintien dans l’inventaire ; protections directement par colonne si nécessaire, sans extension des valeurs du contrat.

### Matrice colonne par colonne à implémenter

| Colonnes / famille | RH_PAIE | Responsables de dépôt | ANALYSTE | TRANSFORMER |
|---|---|---|---|---|
| driver_id | Clair | Clair | Clair | Clair |
| depot | Tous les dépôts | Leur dépôt seulement | Tous les dépôts | Tous |
| first_name, last_name, driver_name | Clair | Clair, leur périmètre | Masqué | Clair |
| phone | Clair | Clair, leur périmètre | Masqué | Clair |
| email, tlc_license_number | Clair | Masqué | Masqué | Clair |
| birth_date | Date complète | NULL | NULL | Date complète |
| birth_year | Année | NULL | Année | Année |
| hire_date, end_date | Clair | NULL | NULL (minimisation retenue) | Clair |
| is_active, tenure_years | Clair | NULL | Clair, analyse du personnel | Clair |
| activity_month, nb_shifts, hours_worked, trips_count, revenue_usd | Clair | NULL (lecture stricte de la matrice, hors exceptions driver_id/depot) | Clair pour analyser l’activité | Clair |

Pour les responsables, le contrat ne prévoit en clair que noms/prénoms/téléphone et l’exception driver_id ; depot reste la clé visible de périmètre, comme le prévoit le test DISTINCT depot du modèle. Les autres attributs sont masqués. Ces choix sont de mise en œuvre, sans changement des rôles ni des catégories de tags.

## 3. Références de volume avant purge

Références anonymes calculées localement sur les fichiers du kit le 6 novembre 2026, en reproduisant le nettoyage du dépôt et le regroupement mensuel des SQL. Totaux confirmés par la capture `08_volumes_initialisation.png` ; répartition par dépôt encore à comparer dans Snowflake. Référence STAGING : dédoublonnage par shift_id ; l’ordre des doublons ex æquo ne doit pas modifier ces regroupements.

| Dépôt | Chauffeurs DIM_DRIVER | Lignes MART_DRIVER_MONTHLY |
|---|---:|---:|
| Queens | 161 | 365 |
| Bronx | 122 | 290 |
| Brooklyn | 117 | 259 |
| Total | 400 | 914 |

## 4. Cahier de tests — attendu / obtenu

Les tests sont **non exécutés, partiels ou observés** selon la colonne obtenu. La démo ne suffit pas à valider toutes les colonnes ni les deux tables métier. Les références sont celles d’avant purge. Après purge, recalculer les références autorisées avec TRANSFORMER ; ne pas exiger artificiellement 400 chauffeurs.

| Test | Rôle / opération | Attendu après politiques | Obtenu | Statut |
|---|---|---|---|---|
| A00 | ANALYSTE, test avant politiques | Cible finale : 400 chauffeurs / 400 prénoms masqués / 0 date complète | Capture : 400 / 0 / 400 | ROUGE observé avant protection |
| A01 | RH_PAIE, comptages | 400 chauffeurs, 914 lignes mensuelles, valeurs autorisées en clair | Résultats du fichier 01 déclarés conformes par Lucas ; captures complémentaires déjà référencées | VERT déclaré et preuve partielle |
| A02 | RESP_DEPOT_QUEENS | 161 chauffeurs, 365 lignes mensuelles ; aucun autre dépôt | Résultats du fichier 01 déclarés conformes par Lucas ; captures complémentaires déjà référencées | VERT déclaré et preuve partielle |
| A03 | RESP_DEPOT_BRONX | 122 chauffeurs, 290 lignes mensuelles ; aucun autre dépôt | Résultats du fichier 01 déclarés conformes par Lucas ; pas de capture dédiée | VERT déclaré  |
| A04 | ANALYSTE | 400 chauffeurs, 914 lignes mensuelles ; noms/téléphone/email/licence masqués ; année seule | Résultats du fichier 01 déclarés conformes par Lucas ; captures complémentaires déjà référencées | VERT déclaré et preuve partielle |
| A05 | GOUVERNANCE lit DIM_DRIVER | Refus d’autorisation | Résultats du fichier 01 déclarés conformes par Lucas ; pas de capture dédiée | VERT déclaré  |
| A06 | ACCOUNTADMIN lit DIM_DRIVER et RAW.DRIVER_SHIFTS | Zéro ligne malgré les droits hérités | Paire 0 / 0 confirmée par Lucas ; DIM_DRIVER également prouvé par 03d | VERT déclaré et capture partielle |
| A07 | RH_PAIE lit RAW.DRIVER_SHIFTS | Refus d’autorisation | Résultats du fichier 01 déclarés conformes par Lucas ; pas de capture dédiée | VERT déclaré  |
| A08 | ANALYSTE lit RAW.DRIVERS | Refus d’autorisation | Résultats du fichier 01 déclarés conformes par Lucas ; pas de capture dédiée | VERT déclaré  |
| A09 | Les quatre métiers lisent DIM_DEPOT | Trois garages sans filtre | Résultats du fichier 01 déclarés conformes par Lucas ; pas de capture dédiée | VERT déclaré  |
| A10 | Responsables : emails/licences/date/année/attributs complémentaires | Aucun email/licence en clair ; dates, année et autres attributs masqués NULL | Résultats du fichier 01 déclarés conformes par Lucas ; pas de capture dédiée | VERT déclaré  |
| A11 | ANALYSTE : identité et date complète | 400 prénoms masqués, 400 noms masqués ; aucun email/téléphone/licence en clair ; zéro date complète ; 400 années | Résultats du fichier 01 déclarés conformes par Lucas ; captures complémentaires déjà référencées | VERT déclaré et preuve partielle |
| A12 | ANALYSTE lit V_CATALOGUE | 25 colonnes, 3 tables, zéro description absente ; 11 écarts de taxonomie signalés | Résultats du fichier 01 déclarés conformes par Lucas ; pas de capture dédiée | VERT déclaré  |
| A13 | TRANSFORMER après reconstruction | 400 chauffeurs avant purge ; zéro email contenant le masque ; zéro écart email avec STAGING ; années cohérentes | 12 contrôles de reconstruction déclarés OK par Lucas, dont fidélité des emails au pipeline | VERT déclaré |
| A14 | Réexécuter les scripts de politiques | Pas d’échec ni perte des règles | Non exécuté | À faire |
| A15 | Réexécuter les transformations | Tags, commentaires et politiques maintenus ; tests A01-A13 encore satisfaits | Reconstruction des trois MARTS puis 12 contrôles déclarés OK ; vérification après tâches encore à réaliser | VERT déclaré sur le périmètre du test 04 |
| A16 | Ajouter un dépôt au rôle Queens via ACCES_DEPOT | Ajouter Bronx donne 283 chauffeurs et 655 lignes mensuelles, sans changer la politique ; restaurer ensuite le mapping | 655 lignes mensuelles rapportées ; restauration 161/365 confirmée ; extension 283/655 non observée ensemble | PARTIEL |
| A17 | Rôle SYSADMIN, absent du mapping | Zéro ligne RH | Non exécuté | À faire |
| A18 | RAW avec ACCOUNTADMIN : noms et emails | Zéro ligne, pas de donnée personnelle à afficher | Non exécuté | À faire |
| A19 | GOUVERNANCE lit RAW ou STAGING | Refus d’autorisation | Non exécuté | À faire |
| A20 | Chaque changement de rôle | USE SECONDARY ROLES NONE puis warehouse ; CURRENT_ROLE attendu | Non exécuté | À faire |

Les assertions de valeurs réelles se font localement dans Snowflake sans copier de noms, emails, téléphones ou licences dans Git. Le SQL publié renvoie des comptes et indicateurs ; il ne publie pas de valeur personnelle du chauffeur témoin. La matrice ci-dessus couvre les mêmes attentes que le tableau de valeurs du modèle.

## 5. Ordre de vérification

1. Exécuter le script de rôles puis la migration birth_year et sa vérification (400, zéro incohérence).
2. Les tests d’identité/filtrage doivent être rouges avant les politiques : constater seulement des agrégats, sans ouvrir les rôles à d’autres utilisateurs. Les refus RAW et GOUVERNANCE peuvent déjà être verts.
3. Implémenter le masquage et le filtrage d’après ces attentes, puis rejouer les blocs et remplir obtenu.
4. Réexécuter le pipeline et vérifier la stabilité ; tester le mapping puis restaurer son état.
5. Ranger les preuves publiques sans données du personnel, indiquer la date et le rôle de chaque exécution.

Sources : contrat §4 ; guide jour 2 ; documentation officielle Snowflake [GRANT](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege), consultée le 6 novembre 2026.

## 6. Résultat avant politiques et implémentation préparée

Capture `10_test_analyste_avant_politiques.png`, reçue le 6 novembre 2026 : 400 chauffeurs, zéro prénom masqué, 400 dates complètes visibles. Test rouge observé sur l’état avant protection ; il ne valide pas les accès finaux. Lucas confirme l’exécution des rôles et de la migration ; vérification de la migration déclarée correcte, sans capture dédiée.

Implémentation préparée : 03_masquage.sql associe au tag une politique VARCHAR, DATE et NUMBER ; l’exception identifiant_interne ne concerne que les rôles métier autorisés, pas tous les rôles du compte. TRANSFORMER et RH_PAIE ont les valeurs nécessaires en clair. Des politiques directes DATE/FLOAT/NUMBER/BOOLEAN protègent aussi les attributs sans catégorie de tag adaptée. Le dépôt reste la clé de la politique par ligne ; on ne lui attache pas simultanément un masque.

04_acces_depot.sql crée la correspondance et une politique appliquée aux quatre tables RH, RAW compris pour ne laisser aucune ligne aux administrateurs. Le mapping est initialisé par MERGE sans effacer les ajouts. La politique se modifie avec ALTER SET BODY ; au rejeu, une attache déjà correcte est conservée, une attache étrangère provoque une erreur. Aucun rôle métier ne reçoit de droits RAW/STAGING.

Scripts complémentaires : tests/02_test_mapping.sql démontre l’ajout temporaire d’un dépôt (rollback du changement) ; tests/03_demo_quatre_roles.sql rejoue une même requête agrégée pour quatre rôles. Tous les résultats après protection restent non exécutés tant que Lucas n’en transmet pas les preuves. Aucune valeur nominative attendue ni obtenue publiée.

Références techniques consultées le 6 novembre 2026 : [ALTER TAG](https://docs.snowflake.com/en/sql-reference/sql/alter-tag), [ALTER COLUMN](https://docs.snowflake.com/en/sql-reference/sql/alter-table-column), [politiques de lignes](https://docs.snowflake.com/en/user-guide/security-row-intro), [POLICY_REFERENCES](https://docs.snowflake.com/en/sql-reference/functions/policy_references).

### Erreur de compilation du masquage — 6 novembre 2026

Lucas signale une erreur de syntaxe sur la deuxième politique du bloc d’attache groupée au tag (ligne 42 de la version initiale). Correctif local : trois instructions ALTER TAG SET MASKING POLICY distinctes avec FORCE, une par type. L’exécution initiale a pu créer les premières politiques sans les attacher ; le script peut être repris depuis le début. Statut : correctif préparé, compilation et tests après protection à confirmer. Aucun test vert ajouté sur cette seule correction.

## 7. Démonstration verte observée — 6 novembre 2026

Même requête agrégée du script tests/03_demo_quatre_roles.sql, quatre captures reçues et vérifiées. Colonnes : rôle, nombre de chauffeurs, prénoms masqués, dates complètes visibles, années visibles. Ces contrôles portent sur DIM_DRIVER, pas sur toutes les règles du cahier.

| Test de démo | Rôle | Attendu (chauffeurs / prénoms masqués / dates / années) | Obtenu sur capture | Statut | Preuve |
|---|---|---|---|---|---|
| D01 | RH_PAIE | 400 / 0 / 400 / 400 | 400 / 0 / 400 / 400 | VERT observé | [03a_acces_rh_paie.png](03a_acces_rh_paie.png) |
| D02 | RESP_DEPOT_QUEENS | 161 / 0 / 0 / 0 | 161 / 0 / 0 / 0 | VERT observé | [03b_acces_queens.png](03b_acces_queens.png) |
| D03 | ANALYSTE | 400 / 400 / 0 / 400 | 400 / 400 / 0 / 400 | VERT observé | [03c_acces_analyste.png](03c_acces_analyste.png) |
| D04 | ACCOUNTADMIN | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | VERT observé | [03d_acces_accountadmin.png](03d_acces_accountadmin.png) |

Les captures sont des résultats agrégés sans noms, coordonnées, licences ni dates individuelles. Elles satisfont la preuve visuelle de comparaison de deux rôles, avec quatre rôles documentés. Les refus d’accès GOUVERNANCE/RAW, le rôle Bronx, les valeurs complémentaires, MART_DRIVER_MONTHLY, le catalogue métier, l’extension du mapping et la stabilité après pipeline restent à vérifier. Ne pas transformer ces tests partiels en un cahier entièrement vert.

### Retours sur les fichiers 01 et 02 — 6 novembre 2026

Lucas déclare les résultats du fichier 01 conformes, sauf une grille interprétée comme « 1 · 0 » sur le bloc attendu zéro/zéro. Cette lecture peut correspondre au numéro de ligne 1 et à la valeur zéro, sans que cela soit confirmé. Le bloc ACCOUNTADMIN affiche désormais les deux compteurs dans un SELECT unique avec des noms explicites ; aucun résultat ambigu déclaré vert.

Pour le mapping, 655 était la sortie du second SELECT, les 283 chauffeurs provenant d’un SELECT distinct. Les deux compteurs sont regroupés dans une seule ligne ; après restauration, ils doivent valoir 161 et 365. Ces clarifications changent uniquement l’affichage des tests, pas les politiques ou le mapping. Ne pas réinsérer une entrée pour afficher un compteur : employer la requête combinée sur l’état présent, puis terminer le ROLLBACK si la transaction de test est encore ouverte.

### Confirmation et simplification des tests — 6 novembre 2026

Lucas confirme ACCOUNTADMIN 0/0 et Queens restauré à 161/365. L’étape étendue n’est pas attestée par un résultat conjoint 283/655 ; A16 reste partiel.

02_test_mapping.sql affiche désormais un tableau final de trois étapes, obtenu et attendu : 161/365, 283/655, 161/365. L’ajout et son retrait sont validés dans des transactions séparées avant changement de rôle ; l’entrée doit être absente au départ, sinon le test s’arrête sans l’écraser. L’état final conserve les habilitations initiales. Cette version remplace le parcours interactif avec ROLLBACK ; les mentions précédentes décrivent l’historique.

04_reconstruction_verification.sql réexécute les trois INSERT OVERWRITE des fichiers métier avec TRANSFORMER, compare emails et source sans les afficher, vérifie maintien des compteurs de tags/politiques de DIM_DRIVER et des descriptions, puis contrôle les accès. Tableau final de 12 assertions, avant purge, toutes attendues OK. Préparé, non exécuté. Le test après tâches devra encore vérifier les quatre tables et l’ensemble du catalogue.

### Correctif du test de reconstruction — 6 novembre 2026

Erreur signalée sur les mots « vide » et « la » : deux commentaires avaient été extraits comme instructions lors de la préparation du script 04. Les deux lignes sont retirées ; les trois INSERT OVERWRITE INTO ont été comparés intégralement aux fichiers rh/marts correspondants, avec recherche ancrée en début de ligne SQL. Ce contrôle local ne confirme pas l’exécution Snowflake. Script corrigé à relancer entièrement ; aucune table, politique ou tag supprimé. Le test de reconstruction reste en attente de résultat.

## 8. Conservation et purge — tests attendus avant exécution

Reconstruction 04 corrigée déclarée OK par Lucas le 6 novembre 2026 ; pas de capture dédiée reçue. L’extension du mapping reste à confirmer par le tableau de trois étapes avant de modifier les volumes.

| Test | Attendu | Obtenu | Statut |
|---|---|---|---|
| R01, conservation_rh.sql | Quatre tables RH, retention_time=1 | Capture 11 : quatre tables à 1, toutes OK | VERT observé |
| R02, purge complète | Aucun chauffeur expiré ni copie liée dans RAW/MARTS | Capture 12 : quatre contrôles de copies expirées à zéro | VERT observé |
| R03, contrôle avant/après | Au 6 novembre 2026 : 46 concernés, 400→354 chauffeurs ; 25 951 services inchangés car aucun ne concerne ces partants | Capture 12 : 354 chauffeurs courants, 25 951 services ; 400 historiques | VERT observé |
| R04, Time Travel | Après purge, l’état RAW.DRIVERS immédiatement antérieur reste lisible et compte 400 chauffeurs | Capture 12, première exécution : historique 400 après purge à 354 | VERT observé |
| R05, délai de Time Travel | Paramètre limité à un jour ; pas d’essai réel après 24 heures à ce stade | Rétention 1 observée ; disparition après 24 h non testée | PARAMÈTRE vérifié, délai réel non testé |

Tests SQL : conservation_rh.sql puis tests/05_preuve_purge.sql. Le second exécute la purge : ne pas purger d’abord ailleurs, sinon la première preuve portera sur un état déjà purgé. Valeurs locales de référence calculées à partir du kit, sans publication d’IDs. Les futures tâches réutiliseront le même bloc de purge. Données historiques soumises aux droits et politiques actuels ; ne pas créer de clone personnel pour cette démonstration.

## 9. Qualité — attentes avant exécution

| Contrôle | Source | Seuil / gravité | Attendu après la purge initiale | Obtenu |
|---|---|---|---|---|
| licence_unique | RAW.DRIVERS, formule fournie du kit | 0, avertissement | 4 anomalies, ALERTE | Capture 06 : 4, ALERTE, conforme |
| email_valide | RAW.DRIVERS, absence de @ ou NULL | 0, avertissement | 7 anomalies, ALERTE | Capture 06 : 7, ALERTE, conforme |
| service_rattache | RAW.DRIVER_SHIFTS, chauffeur absent de RAW.DRIVERS | 50, bloquant seulement au-delà | 25 anomalies, OK | Capture 06 : 25 / 50, OK, conforme |
| Historisation | QUALITE_RESULTATS | Une ligne par règle et exécution | Trois lignes ajoutées à chaque lancement | Non exécuté |
| Blocage | Future tâche T_QUALITE | Mesure > seuil | Résultat committé puis erreur ; T_TABLES ne part pas | Non exécuté |

Ces attentes viennent d’un calcul local sur le kit après exclusion des 46 chauffeurs expirés ; à confronter à Snowflake. La qualité ne corrige pas automatiquement les données. Les avertissements poursuivent la chaîne ; le seuil de 50 ne fait pas disparaître les 25 services orphelins. Les mesures sont validées en transaction avant la levée éventuelle de l’erreur bloquante.

Préférence de preuves de Lucas : annoncer chaque capture avant l’instruction d’exécution et indiquer le point d’arrêt. La première preuve de purge est conservée ; au rejeu, 354 peut devenir la référence historique courante, sans invalider la capture initiale à 400.

## 10. Chaîne quotidienne — attentes avant exécution

Capture 06_resultats_qualite_manuels.png : trois mesures enregistrées au même instant, 6 novembre 2026 à 14:27:08.482 tel qu’affiché par Snowflake ; aucun fuseau déduit du TIMESTAMP_NTZ. Résultats conformes aux attentes. Elle ne prouve pas encore une exécution planifiée ni le blocage.

| Test | Attendu | Obtenu | Statut |
|---|---|---|---|
| T01, création du graphe | T_PURGE → T_QUALITE → T_TABLES ; propriétaire TRANSFORMER, suspendues après création | Non exécuté | À faire |
| T02, exécution normale | Les trois tâches SUCCEEDED dans le même graph_run_group_id | Non exécuté | À faire |
| T03, qualité par tâche | Trois nouvelles mesures, 4/7/25 et ALERTE/ALERTE/OK | Non exécuté | À faire |
| T04, contrôles après tâche | 18 contrôles OK : masques/filtre des quatre tables, descriptions, rétention, source et accès | Non exécuté | À faire |
| T05, règle bloquante | Mesure de service_rattache supérieure au seuil de test : T_QUALITE FAILED, T_TABLES non démarrée, résultat enregistré | Non exécuté | À faire |
| T06, rétablissement | Seuil contractuel 50 rétabli et nouvelle chaîne réussie | Non exécuté | À faire |

La racine est prévue chaque jour à 05:00 Europe/Paris ; ses enfants n’ont pas d’horaire propre. Le rôle propriétaire détermine les accès, pas celui qui regarde l’interface. Les scripts de création laissent le graphe suspendu ; lancer_taches_rh.sql l’active et demande une exécution. Consulter suivi_taches_rh.sql pour le statut, sans redemander une exécution. Suspendre la racine à la fin du brief.
