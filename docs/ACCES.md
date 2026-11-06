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
| A01 | RH_PAIE, comptages | 400 chauffeurs, 914 lignes mensuelles, valeurs autorisées en clair | DIM_DRIVER : 400 chauffeurs, 0 prénom masqué, 400 dates et années visibles ; mensuel/autres valeurs à tester | PARTIEL, capture 03a |
| A02 | RESP_DEPOT_QUEENS | 161 chauffeurs, 365 lignes mensuelles ; aucun autre dépôt | DIM_DRIVER : 161 chauffeurs, 0 prénom masqué, 0 date/année visible ; mensuel et contrôle des autres dépôts à tester | PARTIEL, capture 03b |
| A03 | RESP_DEPOT_BRONX | 122 chauffeurs, 290 lignes mensuelles ; aucun autre dépôt | Non exécuté | À faire |
| A04 | ANALYSTE | 400 chauffeurs, 914 lignes mensuelles ; noms/téléphone/email/licence masqués ; année seule | DIM_DRIVER : 400 chauffeurs, 400 prénoms masqués, 0 date complète, 400 années ; autres champs/mensuel à tester | PARTIEL, capture 03c |
| A05 | GOUVERNANCE lit DIM_DRIVER | Refus d’autorisation | Non exécuté | À faire |
| A06 | ACCOUNTADMIN lit DIM_DRIVER et RAW.DRIVER_SHIFTS | Zéro ligne malgré les droits hérités | DIM_DRIVER : 0 ligne ; RAW.DRIVER_SHIFTS à tester | PARTIEL, capture 03d |
| A07 | RH_PAIE lit RAW.DRIVER_SHIFTS | Refus d’autorisation | Non exécuté | À faire |
| A08 | ANALYSTE lit RAW.DRIVERS | Refus d’autorisation | Non exécuté | À faire |
| A09 | Les quatre métiers lisent DIM_DEPOT | Trois garages sans filtre | Non exécuté | À faire |
| A10 | Responsables : emails/licences/date/année/attributs complémentaires | Aucun email/licence en clair ; dates, année et autres attributs masqués NULL | Non exécuté | À faire |
| A11 | ANALYSTE : identité et date complète | 400 prénoms masqués, 400 noms masqués ; aucun email/téléphone/licence en clair ; zéro date complète ; 400 années | Prénoms 400 masqués, dates complètes 0, années 400 ; noms/email/téléphone/licence à tester | PARTIEL, capture 03c |
| A12 | ANALYSTE lit V_CATALOGUE | 25 colonnes, 3 tables, zéro description absente ; 11 écarts de taxonomie signalés | Non exécuté | À faire |
| A13 | TRANSFORMER après reconstruction | 400 chauffeurs avant purge ; zéro email contenant le masque ; zéro écart email avec STAGING ; années cohérentes | Non exécuté | À faire |
| A14 | Réexécuter les scripts de politiques | Pas d’échec ni perte des règles | Non exécuté | À faire |
| A15 | Réexécuter les transformations | Tags, commentaires et politiques maintenus ; tests A01-A13 encore satisfaits | Non exécuté | À faire |
| A16 | Ajouter un dépôt au rôle Queens via ACCES_DEPOT | Ajouter Bronx donne 283 chauffeurs et 655 lignes mensuelles, sans changer la politique ; restaurer ensuite le mapping | Non exécuté | À faire |
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
