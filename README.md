# Hudson Cab — Gouvernance RH dans Snowflake

Dépôt : [LucasHzl/hudson-cab-gouvernance](https://github.com/LucasHzl/hudson-cab-gouvernance).

Entrepôt pédagogique sur Snowflake Enterprise, AWS Paris : catalogue, accès par rôle et dépôt, conservation, qualité, tâches et audit. Références : [brief](BRIEF.md), [contrat](CONTRAT_GOUVERNANCE.md), [guide](GUIDE_BRIEF_GOUVERNANCE.md).

## État et preuves

Au 6 novembre 2026 : pipeline chargé, accès et mapping testés, purge 400 → 354, rétention un jour, chaîne quotidienne réussie, blocage qualité puis rétablissement prouvés, audit et lignage capturés. Dix-huit contrôles sont verts après reconstruction et après rejeu des politiques.

Le contrôle critère par critère est dans [CONTROLE_RENDU.md](docs/CONTROLE_RENDU.md). Les recettes renforcées sont prouvées : 69 assertions d’accès et six assertions de rejeu, zéro échec (captures 27/28). L’extension de classification est exécutée : 39 colonnes personnelles couvertes, zéro écart (capture 29), et 69 contrôles d’accès de nouveau conformes après migration (capture 30). La couverture C20 est prouvée avec l’extension de taxonomie D01 explicitement documentée. Les bonus ne font pas partie du périmètre.

## Gouvernance

### Ce qui est protégé

Les dix colonnes RH, les huit colonnes des services et leurs dérivations sont personnelles dans leur contexte, y compris les attributs professionnels et les agrégats par chauffeur. Inventaire et registre : [REGISTRE.md](docs/REGISTRE.md). DIM_DEPOT est un référentiel sans données personnelles.

- RH_PAIE : tous les dépôts, données en clair.
- Responsables : leur dépôt seulement, identité et téléphone en clair ; autres attributs masqués, hors driver_id et clé depot.
- ANALYSTE : tous les dépôts, identité/coordonnées/licence masquées, année de naissance seule ; mesures d’activité utilisables.
- TRANSFORMER : lecture nécessaire en clair pour charger, contrôler, purger et reconstruire.
- GOUVERNANCE : règles et métadonnées, pas de SELECT sur le personnel.
- ACCOUNTADMIN et SYSADMIN : zéro ligne personnelle avec le mapping actuel. Leurs pouvoirs de reconfiguration restent une limite.

La politique de lignes utilise CURRENT_ROLE et ACCES_DEPOT ; le lecteur n’a pas besoin de lire le mapping. Les rôles secondaires sont désactivés dans les tests. Classification par tag sur toutes les colonnes personnelles ; masques attachés directement aux colonnes à protéger. La politique textuelle consulte leur catégorie. DEPOT reste sans masque car il est la clé du filtre. Cette évolution est validée par les captures 29 et 30. Les dates, nombres et booléens masqués deviennent NULL ; les textes deviennent [MASQUE] en conservant les NULL sources. Matrice et carte des privilèges : [ACCES.md](docs/ACCES.md).

### Installation depuis un compte vide

Prérequis : Snowflake Enterprise, fichiers drivers.csv et driver_shifts.csv disponibles localement depuis le [kit officiel](https://github.com/gsoulat/formation-data-IA/tree/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance/starter-kit/data). Les données sources ne sont pas livrées dans ce dépôt public. Exécuter les fichiers entiers, sans remplacer les rôles indiqués par ACCOUNTADMIN. Python/uv ne sont pas nécessaires au pipeline SQL.

| Étape | Fichiers / opération | Rôle et résultat |
|---|---|---|
| 1 | snowflake/00_installation.sql | ACCOUNTADMIN crée NYC_TAXI, NYC_TAXI_WH et TRANSFORMER |
| 2 | Lire docs/VEILLE.md et docs/REGISTRE.md | Droit applicable, données et écarts identifiés avant politiques |
| 3 | snowflake/rh/chargement_rh_1_preparer.sql | TRANSFORMER : format CSV, stage, tables RAW |
| 4 | Déposer les deux CSV dans NYC_TAXI.RAW.RH_STAGE via Snowsight | Seule opération de dépôt de fichiers ; ne pas publier les CSV |
| 5 | snowflake/rh/chargement_rh_2_copier.sql | TRANSFORMER : 400 chauffeurs, 25 951 services initialement, stage vide |
| 6 | snowflake/rh/00_tables_rh.sql ; staging/stg_rh__drivers.sql ; staging/stg_rh__driver_shifts.sql | Chemins staging/ relatifs à snowflake/rh/ ; tables et vues typées |
| 7 | Dans snowflake/rh/marts/ : dim_depot.sql, dim_driver.sql, mart_driver_monthly.sql | TRANSFORMER : 3 dépôts, 400 chauffeurs, 914 lignes mensuelles ; STAGING services 25 933 |
| 8 | snowflake/gouvernance/01_gouvernance.sql | ACCOUNTADMIN puis GOUVERNANCE : schéma, trois tags, table qualité et droits |
| 9 | snowflake/rh/01_annee_naissance.sql | Migration rejouable birth_year pour un ancien schéma ; déjà présente sur une installation neuve |
| 10 | Dans snowflake/rh/catalogue/ : catalogue_dim_depot.sql, catalogue_raw_drivers.sql, catalogue_raw_driver_shifts.sql, catalogue_dim_driver.sql, catalogue_mart_driver_monthly.sql ; puis vue_catalogue.sql, verifier_catalogue.sql | TRANSFORMER : descriptions des cinq tables et 47 colonnes, tags ; catalogue métier de 25 colonnes |
| 11 | snowflake/gouvernance/02_roles_metier.sql | Crée les quatre rôles et leurs droits sur le compte de test ; ne pas distribuer les accès à d’autres comptes avant validation |
| 12 | Tests d’accès attendus dans docs/ACCES.md ; tests/01_tests_acces.sql et tests/03_demo_quatre_roles.sql | Chemins tests/ relatifs à snowflake/gouvernance/ ; observer le test rouge avant politiques, sans publier de valeurs personnelles |
| 13 | snowflake/gouvernance/03_masquage.sql puis 04_acces_depot.sql | GOUVERNANCE : masques, mapping et filtre sur les quatre tables personnelles |
| 14 | tests/01_tests_acces.sql, blocs séparés selon le rôle | Références initiales avant purge ; les refus attendus sont des résultats de test |
| 15 | snowflake/rh/conservation_rh.sql puis tests/05_preuve_purge.sql | TRANSFORMER : quatre rétentions à un jour, première preuve avant/après ; ne pas lancer purge_rh.sql avant cette première preuve |
| 16 | snowflake/rh/qualite_rh.sql | Trois règles enregistrées, puis erreur si service_rattache dépasse 50 |
| 17 | snowflake/rh/taches_rh.sql, puis lancer_taches_rh.sql une fois ; suivi_taches_rh.sql pour consulter | TRANSFORMER : création suspendue, activation, chaîne purge → qualité → reconstruction ; attendre trois SUCCEEDED |
| 18 | tests/06_verifier_apres_taches.sql et snowflake/rh/consulter_qualite.sql | Dix-huit contrôles, dont masques/filtres des quatre tables et descriptions conservées |
| 19 | tests/07_preparer_blocage.sql ; rh/lancer_taches_rh.sql, rh/suivi_taches_rh.sql et rh/consulter_qualite.sql | Chemins rh/ relatifs à snowflake/ ; seuil temporaire 0 : qualité FAILED, reconstruction non démarrée, résultats conservés |
| 20 | tests/08_retablir_seuil.sql puis mêmes scripts de lancement/suivi/qualité | Seuil normal 50 rétabli, nouvelle chaîne réussie ; ne pas laisser le seuil de test actif |
| 21 | snowflake/gouvernance/06_audit.sql | ACCOUNTADMIN : audit agrégé public sur sept jours ; complément nominatif 06b_audit_detail_prive.sql uniquement en privé |
| 22 | MART_DRIVER_MONTHLY → Lineage dans Snowsight, sous TRANSFORMER | Sources DIM_DRIVER et STAGING services ; capture 04 |
| 23 | tests/02_test_mapping.sql, tests/09_stage_vide.sql | Références dynamiques avant/après purge, extension temporaire puis restauration ; stage zéro fichier |
| 24 | Rejouer 03_masquage.sql et 04_acces_depot.sql, puis tests/06_verifier_apres_taches.sql | Dix-huit contrôles verts après rejeu des règles, capture 26 |
| 25 | tests/10_recette_complete.sql puis tests/11_rejeu_chargement.sql | Recettes finales dynamiques prouvées : 69 assertions sur huit rôles, puis deux rejeux et six assertions, captures 27/28 |
| 25 bis | Sur l’installation existante : snowflake/gouvernance/05_completer_tags.sql, puis tests/12_couverture_tags.sql et tests/10_recette_complete.sql | Migration autonome, sans lancement de tâches ; cinq lignes de couverture OK puis 69 assertions conformes observées, captures 29/30. Sur compte neuf, les huit catégories, fiches complètes et masques directs sont déjà dans les scripts 01/03 et catalogue ; la migration peut être rejouée |
| 26 | snowflake/rh/suspendre_taches_rh.sql après la dernière exécution terminée | Suspend les prochains départs quotidiens sans supprimer les objets |

Ne pas relancer le chargement initial ou les références à 400 pour « réparer » un résultat après purge. Les tests 02, 06, 10 et 11 s’adaptent à l’état courant. Le test Time Travel enregistre un nouvel instant à chaque rejeu : la première capture à 400 reste la preuve de la purge initiale.

### Chargement et rejouabilité

CSV_RH règle le séparateur, les guillemets, l’en-tête et les valeurs vides. RH_STAGE reçoit temporairement les fichiers. COPY INTO associe les champs aux colonnes et enregistre le nom du fichier et l’heure d’ingestion ; ON_ERROR=ABORT_STATEMENT refuse la commande fautive. PURGE=TRUE retire les fichiers chargés avec succès. Les deux COPY ne constituent pas une transaction globale atomique.

Le chargement conserve les deux COPY du kit, sans FORCE. Un contrôle LIST préalable fait du stage vide un rejeu explicite sans écriture ; si des fichiers sont présents, le suivi natif de COPY reste applicable. La recette 11 vérifie deux rejeux avec stage vide et compare les volumes et empreintes des RAW, sans publier ces empreintes. Le suivi des fichiers n’est pas une déduplication métier ni une stratégie de rapprochement d’un nouveau fichier complet.

STAGING nettoie et dédoublonne sans réécrire RAW. Les trois INSERT OVERWRITE reconstruisent les contenus de MARTS sans recréer les tables : protections, tags, descriptions et privilèges survivent. Les politiques utilisent CREATE IF NOT EXISTS puis ALTER ; les attaches et le mapping sont rejouables. Rejouer le catalogue avec ses fiches après une évolution du schéma.

### Conservation et qualité

R1 : end_date strictement antérieure à DATEADD(year,-5,CURRENT_DATE()). Le bloc transactionnel supprime les copies mensuelles, la dimension, les services RAW puis DRIVERS. STAGING reflète RAW ; DIM_DEPOT reste intact. Au 6 novembre 2026, 46 chauffeurs sont expirés : 354 restants ; aucun service ne leur est rattaché dans le jeu, donc 25 951 services et 914 lignes mensuelles restent. Les 25 orphelins préexistants relèvent de la qualité.

R2 : DATA_RETENTION_TIME_IN_DAYS=1 sur les quatre tables permanentes ; R3 : stage vide. Le tag DUREE_CONSERVATION documente la durée, il ne purge rien. Une tâche quotidienne peut laisser jusqu’à environ 24 heures avant son prochain passage. Un jour de Time Travel est suivi de sept jours de Fail-safe sur ces tables ; cela ne prouve pas un effacement physique immédiat ni la suppression des copies externes.

| Contrôle sur RAW | Mesure | Seuil | Gravité / comportement |
|---|---|---|---|
| licence_unique | COUNT(*)−COUNT(DISTINCT licence), règle fournie | 0 | Avertissement ; 4 anomalies observées |
| email_valide | Email NULL ou sans @ | 0 | Avertissement ; 7 anomalies observées |
| service_rattache | Service sans chauffeur connu, NOT EXISTS | 50 | Bloquant au-delà ; 25 observés, OK au seuil normal |

licence_unique compte aussi les NULL si présents ; email_valide ne vérifie ni délivrabilité ni identité. Les trois mesures sont committées avant toute erreur bloquante. Les avertissements continuent la chaîne ; le blocage empêche T_TABLES. Les cinq autres règles proposées au contrat ne sont pas nécessaires au minimum de trois implémenté.

Les tâches sont détenues par TRANSFORMER, sur NYC_TAXI_WH. La racine est prévue chaque jour à 05:00 Europe/Paris ; les enfants utilisent AFTER. Les lancements observés sont manuels : le départ automatique à l’horaire n’a pas été observé. Modifier le graphe hors exécution active, après suspension de la racine. Le suivi rassemble le même graph_run_group_id et la même tentative, sans mélanger les groupes.

### Audit et lignage

ACCESS_HISTORY fournit les objets et colonnes ; QUERY_HISTORY apporte le rôle via query_id. L’audit public groupe par rôle/type et ne contient ni compte utilisateur ni texte SQL. Le complément privé retrouve les comptes ; sa sortie ne doit pas entrer dans Git. Un objet référencé ne prouve ni ligne retournée ni valeur visible en clair. Délai possible de trois heures, donc résultat vide ne signifie pas absence de lecture.

Le lignage montre DIM_DRIVER et STAGING.STG_RH__DRIVER_SHIFTS vers MART_DRIVER_MONTHLY. V_CATALOGUE apparaît en aval ; cette dépendance de métadonnées ne signifie pas que les valeurs RH y sont copiées.

### Écarts au contrat et limites

1. **Extension documentée de la taxonomie** : les six catégories initiales ne couvrent pas vingt attributs personnels. La décision D01 ajoute donnee_professionnelle et activite, avec dix affectations chacune, sans changer les noms des trois tags ni la matrice des accès. Cette extension s’écarte littéralement des valeurs initiales du contrat ; la justification et les tests figurent dans [DECISIONS.md](docs/DECISIONS.md). Couverture observée : 39 colonnes, zéro manque ; migration et stabilité des lectures prouvées par les captures 29/30. Les captures 31a/31b montrent les 13 colonnes de DIM_DRIVER taguées.
2. **Cinq ans uniformes non justifiés par catégorie** : règle appliquée pour l’exercice ; base légale et durée par usage à établir. Les contrats new-yorkais ne relèvent pas automatiquement des durées RH françaises du référentiel CNIL du 2 avril 2026.
3. **Base active et archive non distinguées** : accès aux anciens chauffeurs maintenus selon le contrat ; proposer archive restreinte et durées par finalité.
4. **Rétention technique** : Time Travel, Fail-safe et copies annexes distincts ; pas d’essai d’effacement physique après huit jours.
5. **Pouvoirs administratifs** : TRANSFORMER possède les tables et les administrateurs peuvent reconfigurer les règles. Les tests de lecture ne neutralisent pas ces pouvoirs.
6. **Qualité et nouvelles livraisons** : avertissement n’est pas correction. Un nouveau snapshot complet nécessite une stratégie de remplacement/rapprochement, validation et purge avant réexposition ; non implémentée par les deux COPY seuls.

La confrontation de chaque règle aux textes figure dans [VEILLE.md](docs/VEILLE.md), notamment les huit contrôles qualité, rôles, catalogue et conservation. Réponses aux questions de conception : [QUESTIONS.md](docs/QUESTIONS.md).

### Dépôt public et livrables

Les CSV du personnel, .venv, secrets, clés et connexions sont exclus par .gitignore. Les captures contiennent des agrégats, masques ou métadonnées. Les modèles vierges et la copie de README destinée au formateur ont été retirés ; les documents de référence restent identifiés comme tels. La publication des commits se fait après inspection du contenu, sans ajouter les CSV ni les sorties nominatives.

- [VEILLE.md](docs/VEILLE.md) : droit, cinq fiches, suivi et confrontation.
- [REGISTRE.md](docs/REGISTRE.md) : inventaire des sources et dérivations, registre et preuves.
- [ACCES.md](docs/ACCES.md) : propriété, privilèges, matrice et cahier de tests.
- [SUIVI.md](docs/SUIVI.md) : index des captures et état actuel.
- [CONTROLE_RENDU.md](docs/CONTROLE_RENDU.md) : critères hors bonus, preuves et réserves.
- [QUESTIONS.md](docs/QUESTIONS.md), [DECISIONS.md](docs/DECISIONS.md) et [SOUTENANCE.md](docs/SOUTENANCE.md) : réponses, choix de conception et déroulé oral.
- snowflake/gouvernance/ et snowflake/rh/ : scripts versionnés.

Sources techniques : [COPY INTO](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table), [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel), [Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe), [tâches](https://docs.snowflake.com/en/user-guide/tasks-graphs), [ACCESS_HISTORY](https://docs.snowflake.com/en/sql-reference/account-usage/access_history). Sources juridiques et dates dans la veille.
