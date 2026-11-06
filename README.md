# Hudson Cab — Gouvernance des données RH dans Snowflake

Projet pédagogique : catalogue, accès, conservation, qualité et audit des données de chauffeurs fictifs. Référence : `CONTRAT_GOUVERNANCE.md`. Les exigences sont confrontées aux textes dans `docs/VEILLE.md`.

## État du projet

En cours au 6 novembre 2026. Compte Enterprise d’essai sur AWS Paris et installation réussie déclarés par l’étudiant ; volumes STAGING/MARTS vérifiés sur capture fournie par l’étudiant, sans connexion directe de l’assistant à Snowflake. Voir `docs/SUIVI.md` pour les validations et preuves restantes.

## Gouvernance

### Protection du dépôt public

Les deux CSV RH restent locaux et sont exclus par `.gitignore`, même s’ils sont fictifs : le projet reproduit les précautions d’un traitement réel de données du personnel. Aucun secret ni donnée personnelle ne doit être publié, y compris dans les résultats de tests et captures. Vérifier les fichiers avant chaque commit. `.venv/` est exclu ; `pyproject.toml` et `uv.lock` peuvent être versionnés. Python et uv ne sont pas nécessaires pour exécuter le kit dans Snowsight.

### Principes et choix établis

- `TRANSFORMER` porte le chargement et le pipeline, avec les droits nécessaires à ses opérations.
- Dans le scénario, Hudson Cab Europe décide du traitement. Le droit applicable et les sources figurent dans `docs/VEILLE.md`, section 1.
- Les fichiers SQL sont conservés dans le dépôt et exécutés dans Snowsight. Toute modification durable doit se retrouver dans un script rejouable.
- Les 18 colonnes sources et leurs dérivations ont été inventoriées dans `docs/REGISTRE.md` ; protections et durées restent à mettre en œuvre. Aucun accès métier n’est encore déclaré ouvert.

### Ordre d’exécution

1. `snowflake/00_installation.sql`, avec `ACCOUNTADMIN` : warehouse, base, schémas et rôle `TRANSFORMER`. Exécution réussie rapportée par l’étudiant.
2. Avant chargement : relire la veille et l’inventaire, vérifier la preuve d’inscription CNIL dans `docs/01_abonnement_veille.png`, compléter les suivis de veille et vérifier les exclusions Git.
3. `snowflake/rh/chargement_rh_1_preparer.sql`, avec `TRANSFORMER` : créer format CSV, stage et tables RAW.
4. Déposer localement les deux fichiers CSV dans `NYC_TAXI.RAW.RH_STAGE` via Snowsight ; vérifier leur présence avec `LIST @NYC_TAXI.RAW.RH_STAGE;`.
5. `snowflake/rh/chargement_rh_2_copier.sql`, avec `TRANSFORMER` : charger puis retirer les fichiers du stage. Comptages 400 chauffeurs et 25 951 services confirmés par l’étudiant le 6 novembre 2026 ; capture non reçue. Stage vide rapporté dans le contexte du message « Query produced no results » ; vérification visuelle indépendante et test de rejouabilité encore à consigner.
6. `snowflake/rh/00_tables_rh.sql`, puis `snowflake/rh/staging/stg_rh__drivers.sql`, `snowflake/rh/staging/stg_rh__driver_shifts.sql`, `snowflake/rh/marts/dim_depot.sql`, `snowflake/rh/marts/dim_driver.sql` et `snowflake/rh/marts/mart_driver_monthly.sql`. Volumétrie avant purge vérifiée sur capture le 6 novembre 2026 : 25 933 services dans STAGING ; 3 dépôts, 400 chauffeurs et 914 lignes mensuelles dans MARTS. Preuve : `docs/08_volumes_initialisation.png`.
7. `snowflake/gouvernance/01_gouvernance.sql` : démarre avec ACCOUNTADMIN puis passe à GOUVERNANCE ; crée le rôle, le schéma, les trois tags, QUALITE_RESULTATS et les droits utiles à TRANSFORMER. Exécution réussie et trois tags confirmés par l’étudiant le 6 novembre 2026 ; absence de SELECT RH à tester séparément.
8. `snowflake/rh/01_annee_naissance.sql`, avec TRANSFORMER : migration rejouable de la table existante, description et tag de birth_year. À faire avant de rejouer la fiche complète DIM_DRIVER sur un ancien schéma. Exécution réussie déclarée par Lucas le 6 novembre 2026 ; contrôle agrégé correct selon son retour.
9. Avec TRANSFORMER, exécuter dans `snowflake/rh/catalogue/` : `catalogue_dim_depot.sql`, `catalogue_raw_drivers.sql`, `catalogue_raw_driver_shifts.sql`, `catalogue_dim_driver.sql`, `catalogue_mart_driver_monthly.sql`, puis `vue_catalogue.sql` et `verifier_catalogue.sql`. État initial à 24 colonnes métier vérifié sur export ; état étendu après migration attendu : 47 colonnes décrites sur cinq tables et 25 lignes dans V_CATALOGUE. La vue porte sur MARTS uniquement.
10. `snowflake/gouvernance/02_roles_metier.sql` : préparation des quatre rôles pour le compte pédagogique ; exécution réussie déclarée par Lucas le 6 novembre 2026. Cahier des résultats attendus déjà écrit dans `docs/ACCES.md`, SQL de tests dans `snowflake/gouvernance/tests/01_tests_acces.sql`.
11. `snowflake/gouvernance/03_masquage.sql`, puis `04_acces_depot.sql`, avec GOUVERNANCE ; exécution réussie confirmée et démo de quatre rôles vérifiée sur captures. Rejouer ensuite les blocs de `tests/01_tests_acces.sql` et la démonstration `tests/03_demo_quatre_roles.sql`.
12. `snowflake/rh/conservation_rh.sql` (quatre rétentions à un jour), puis `snowflake/gouvernance/tests/05_preuve_purge.sql` pour la première purge avec preuve avant/après et Time Travel. Le second contient le même bloc que `snowflake/rh/purge_rh.sql` ; ne pas lancer ce dernier avant la première démonstration. Rétention et première preuve de purge vérifiées sur captures le 6 novembre 2026 : 354 chauffeurs courants, 400 historiques, zéro copie expirée.
13. `snowflake/rh/qualite_rh.sql`, avec TRANSFORMER : trois règles, journalisation durable puis blocage si service_rattache dépasse 50. Trois mesures vérifiées sur capture : 7 emails, 4 licences, 25 services orphelins, statuts attendus. Les requêtes scalaires sont documentées dans `rh/controles/`.
14. `snowflake/rh/taches_rh.sql`, avec TRANSFORMER : crée/modifie la chaîne suspendue. Puis `lancer_taches_rh.sql` pour l’activer et demander un lancement ; `suivi_taches_rh.sql` pour lire le résultat du même lancement. Première exécution complète réussie le 6 novembre 2026, captures 13 et 14 : propriétaire TRANSFORMER, trois SUCCEEDED dans le même groupe. Départ automatique à 05:00 non encore observé.
15. `snowflake/gouvernance/tests/06_verifier_apres_taches.sql` contrôle les protections, descriptions, rétention, valeurs et accès ; `consulter_qualite.sql` lit les dernières mesures sans en créer.
16. Restent le test bloquant, l’audit, le lignage et la finalisation documentaire. `suspendre_taches_rh.sql` arrête les départs automatiques à la fin du brief. Ce README ne permet pas encore de rejouer l’intégralité du projet.

### Comprendre le chargement

- Le format `CSV_RH` définit la lecture des fichiers : CSV, en-tête ignoré et guillemets reconnus. Il ne contient pas les données.
- Le stage `RH_STAGE` stocke temporairement les fichiers ; ce n’est pas une table de lignes SQL.
- `COPY INTO` lit les colonnes du fichier, convertit les types et remplit RAW. Les colonnes `_source_file` et `_loaded_at` conservent la provenance et le moment du chargement.
- `ON_ERROR = ABORT_STATEMENT` arrête la commande COPY concernée si une erreur de chargement est détectée ; les deux COPY ne constituent pas à eux seuls une opération globale atomique.
- `PURGE = TRUE` demande le retrait des fichiers chargés avec succès. Vérifier le stage avec LIST : zéro ligne est attendu et ne signifie pas un échec.
- La rejouabilité immédiate doit être vérifiée par une seconde exécution et des comptages inchangés. Ne pas ajouter `FORCE = TRUE`, qui contournerait la protection contre le rechargement des fichiers connus. Ne pas confondre cette protection avec une déduplication métier permanente.
- Les vues STAGING nettoient et dédoublonnent ; les scripts MARTS utilisent `INSERT OVERWRITE` pour remplir les tables existantes sans les recréer. Les futures protections doivent survivre à cette reconstruction des contenus.

### Écarts au contrat et limites connues

Analyse règle par règle à poursuivre. Écart de couverture du catalogue : les six valeurs permises de `DONNEE_PERSONNELLE` ne couvrent pas explicitement toutes les données personnelles inventoriées : affectation, dates professionnelles, activité et certains attributs calculés. Les agrégats par chauffeur restent personnels. Décision : conserver la taxonomie imposée et consigner cette incompatibilité ; aucune extension de valeurs n’est retenue. La durée uniforme de cinq ans demande une justification par finalité et obligations applicables : point à examiner, pas conclusion de conformité. Les résultats de tests, abonnements et captures ne seront validés qu’après réalisation effective.

### Écarts de conservation identifiés

- **Durée de cinq ans non justifiée par catégorie** : le contrat fixe un délai uniforme sans fournir sa base par finalité. Les durées RH françaises ne se transposent pas automatiquement aux chauffeurs sous contrats new-yorkais. Le référentiel CNIL publié le 2 avril 2026 précise son périmètre français. Sources et analyse dans `docs/VEILLE.md`, fiches 2 à 4.
- **Base active et archivage intermédiaire non distingués** : conserver pour un litige ou une obligation peut justifier certains éléments, avec accès restreint, plutôt que l’intégralité du dossier dans les usages courants. Proposition à soumettre au DPO ; matrice du brief maintenue pour les tests, aucune modification silencieuse.
- **Time Travel ne couvre pas toute la rétention technique** : sur les tables permanentes, sept jours de Fail-safe suivent Time Travel ; limiter ce dernier à un jour ne signifie pas destruction physique au lendemain de la purge. Documentation Snowflake citée dans la veille.
- **Limites complémentaires** : identifiant interne et agrégats par chauffeur restent personnels ; seuils qualité et droits de la paie demandent justification, pas simple assimilation à une conformité juridique. Comparaison détaillée, incluant les huit règles qualité, dans la veille.

## Livrables

- `docs/VEILLE.md` : droit applicable, dispositif, quatre fiches et confrontation du contrat.
- `docs/REGISTRE.md` : inventaire, copies des données et registre du traitement.
- `docs/ACCES.md` : droits et tests, attendu avant politique puis obtenu après exécution.
- `docs/SUIVI.md` : avancement et liste des preuves visuelles.
- `snowflake/gouvernance/` et `snowflake/rh/` : scripts du kit et futurs scripts du projet.

## Preuves visuelles

- [Inscription à la lettre CNIL enregistrée](docs/01_abonnement_veille.png), capture fournie et vérifiée le 6 novembre 2026. Référencée dans la note de veille. Les captures suivantes seront ajoutées au fil des validations.

- [Volumes initiaux STAGING et MARTS](docs/08_volumes_initialisation.png), capture vérifiée le 6 novembre 2026 : 25 933, 3, 400 et 914 lignes.

### État de la couverture du catalogue

Chaque colonne des cinq tables a une description prévue, et chaque table sa sensibilité et sa durée. Les tags de nature sont posés uniquement lorsque l’une des six valeurs imposées convient. Les autres données professionnelles personnelles restent identifiées dans les descriptions et l’inventaire ; V_CATALOGUE les signale par personnelle_inventoriee et ECART_TAG_CONTRAT. Ce signalement répond à la consigne de déclarer les écarts, mais ne suffit pas à satisfaire entièrement l’exigence C20 « toutes les colonnes personnelles taguées ». Cette limite doit être présentée au formateur, sans attestation de validation anticipée. Aucun type de tag n’est inventé ni utilisé avec un sens trompeur. La vue métier et ses droits doivent encore être testés avec les futurs rôles.

### Décision après relecture des attentes — 6 novembre 2026

Le contrat (introduction et section 3) fixe les valeurs ; le guide (étape 0 et jour 1, étape 6) demande de signaler les écarts sans réécrire le contrat. Le brief C20 exige parallèlement un tag sur toute colonne personnelle de l’inventaire. Notre inventaire large inclut des attributs professionnels et d’activité qui ne correspondent à aucune des six valeurs de nature prévues. Ces exigences ne peuvent pas être satisfaites simultanément pour ces attributs tout en conservant le sens exact des étiquettes.

Décision : conserver les trois tags et les six valeurs, maintenir toutes les colonnes personnelles dans l’inventaire et les descriptions, appliquer les catégories adaptées et signaler les autres comme ECART_TAG_CONTRAT. Ne pas déclarer ces colonnes non personnelles pour faire passer le contrôle ; ne pas appeler une date de contrat date_naissance ni une recette identifiant_interne. Le critère de couverture C20 reste partiellement non satisfait, explicitement expliqué. Seul le formateur peut confirmer l’acceptation pédagogique de ce constat.

L’absence de catégorie adaptée ne dispense pas de protection : les droits, politiques par colonne si nécessaire, filtrage par dépôt, purge et audit doivent couvrir ces données selon les besoins et la matrice. Aucun accès métier n’est ouvert à ce stade. La proposition d’extension a été retirée des scripts du dépôt ; aucune extension n’a été déclarée exécutée dans Snowflake.

Sources du choix : `CONTRAT_GOUVERNANCE.md` introduction et §3 ; `GUIDE_BRIEF_GOUVERNANCE.md` étape 0, jour 1 étapes 6 et 11 ; `BRIEF.md` C20 ; `docs/VEILLE_MODELE.md` §4. Les transformations SQL sont modifiables ; cela ne donne pas autorisation de réécrire les valeurs imposées du contrat.

Preuves conservées : [export du catalogue](docs/09_catalogue_avant_correction.csv) et [tags des colonnes de DIM_DRIVER](docs/02_tags_dim_driver_avant_correction.png). Les noms historiques « avant correction » ne préjugent pas d’une extension future : ils désignent l’état reçu. Aucun changement Snowflake n’est nécessaire pour appliquer cette décision documentaire.

## Accès : préparation avant les politiques

Le 6 novembre 2026, le cahier `docs/ACCES.md` et le SQL `snowflake/gouvernance/tests/01_tests_acces.sql` sont écrits avant les scripts 03/04. Ils fixent les masques, les volumes par dépôt et les résultats attendus ; aucun résultat obtenu n’est inventé.

Prochain ordre : `snowflake/gouvernance/02_roles_metier.sql` (ACCOUNTADMIN, droits des quatre métiers), puis `snowflake/rh/01_annee_naissance.sql` (TRANSFORMER, migration de la table existante). Ensuite seulement écrire et appliquer les politiques. Les rôles ne sont attribués qu’à l’utilisateur courant de test ; ouverture métier après validation.

Choix de minimisation : conserver la date complète pour RH_PAIE, créer birth_year pour ANALYSTE, masquer la date complète pour l’analyste et les responsables. Dates d’embauche/fin masquées pour ANALYSTE ; activité et statut accessibles pour l’analyse. Pour les responsables, lecture stricte des valeurs autorisées : noms et téléphone, plus identifiant et dépôt nécessaires au périmètre ; les autres attributs restent masqués.

Les scripts de création et transformation de DIM_DRIVER sont adaptés : liste explicite des colonnes de l’INSERT OVERWRITE et calcul de birth_year, sans recréer la table. La migration ajoute une colonne ; après elle, le catalogue MARTS comporte 25 lignes (DIM_DRIVER : 13) et les cinq tables totalisent 47 colonnes, toutes à décrire. Les captures précédentes restent des preuves datées de l’état initial à 24/46 colonnes.

Sur un compte neuf : 00_tables_rh.sql crée déjà birth_year ; les transformations la remplissent. Sur le compte existant : exécuter 01_annee_naissance.sql avant de relancer dim_driver.sql ou catalogue_dim_driver.sql. La migration pose description et tag elle-même ; V_CATALOGUE reflète automatiquement la colonne.

### Politiques préparées après le test rouge

La [capture avant protection](docs/10_test_analyste_avant_politiques.png) montre 400 dates complètes accessibles à ANALYSTE et zéro prénom masqué. Les politiques sont écrites ensuite : masque par tag pour identité/coordonnées/date/année, masques directs pour les autres attributs, accès par dépôt piloté par ACCES_DEPOT sur les quatre tables RH. CURRENT_ROLE est utilisé explicitement ; rôle absent du mapping : aucune ligne. DIM_DEPOT n’est pas filtrée. Les futurs résultats verts et la rejouabilité restent à vérifier dans Snowflake.

### Preuves d’accès après politiques

Le 6 novembre 2026, les quatre résultats de `tests/03_demo_quatre_roles.sql` sont vérifiés : [paie](docs/03a_acces_rh_paie.png), [Queens](docs/03b_acces_queens.png), [analyste](docs/03c_acces_analyste.png), [administrateur](docs/03d_acces_accountadmin.png). Le passage rouge → vert est prouvé pour le prénom et la date complète côté analyste ; le nombre de chauffeurs est limité à 161 pour Queens et à zéro pour ACCOUNTADMIN. Le cahier complet, le mensuel et le maintien après pipeline restent à vérifier ; voir les statuts détaillés dans ACCES.md.

### Vérifications synthétiques avant purge

Dans `snowflake/gouvernance/tests/`, exécuter `02_test_mapping.sql` en entier dans une même feuille : trois étapes dans le résultat final, toutes attendues OK. Il ajoute puis retire la seule habilitation de test ; pas de changement des politiques. Ensuite, `04_reconstruction_verification.sql` en entier : reconstruit les trois tables MARTS avec les INSERT OVERWRITE et affiche 12 contrôles, tous attendus OK avant purge. Scripts prêts mais résultats encore à confirmer.

### Conservation et purge : choix de mise en œuvre

R1 est implémentée avec end_date strictement antérieure à DATEADD(year,-5,CURRENT_DATE()) ; un chauffeur en poste (NULL) reste conservé. Les copies MARTS et services RAW sont supprimées avant RAW.DRIVERS, dans une transaction avec rollback sur erreur. Les vues STAGING reflètent la source ; aucune table ni protection n’est recréée. La table de dépôts, non personnelle, reste intacte.

Au 6 novembre 2026, référence locale du kit : 46 chauffeurs concernés, donc 354 restants ; aucun service ne concerne ces 46 chauffeurs dans le jeu fourni, donc 25 951 services restent. Le DELETE des services est néanmoins indispensable pour les futurs fichiers. Les 25 services orphelins existants ne sont pas automatiquement attribuables à des chauffeurs expirés : ils relèvent du contrôle service_rattache.

R2 est un paramètre de table, pas le tag DUREE_CONSERVATION. Les quatre tables permanentes sont limitées à un jour de Time Travel, suivi des sept jours de Fail-safe documentés dans la veille. La purge quotidienne introduira un délai de passage allant jusqu’à environ 24 heures ; les CSV locaux et sauvegardes externes ne sont pas effacés par une requête Snowflake. Si un fichier complet historique est rechargé, la purge doit être réappliquée avant reconstruction et ouverture des usages ; la déduplication de COPY ne remplace pas cette règle.

Sources techniques consultées le 6 novembre 2026 : [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel), [AT/BEFORE](https://docs.snowflake.com/en/sql-reference/constructs/at-before). Les scripts sont préparés, leur exécution reste à confirmer.

### Captures de conservation et règles de qualité

Preuves vérifiées : [rétention des quatre tables](docs/11_retention_un_jour.png), [première purge et Time Travel](docs/12_purge_et_time_travel.png). Le rejeu du fichier de preuve prend un nouvel instant : il ne doit pas être utilisé pour retrouver automatiquement la référence initiale à 400.

Qualité préparée : licence_unique, seuil zéro, avertissement ; email_valide, seuil zéro, avertissement ; service_rattache, seuil 50, blocage au dépassement. Chaque exécution ajoute trois lignes dans QUALITE_RESULTATS, sans valeurs personnelles. Le résultat du contrôle bloquant est committé avant l’erreur afin de conserver la preuve. Attendus locaux après purge : 4 / 7 / 25 anomalies ; ALERTE / ALERTE / OK. Une alerte qualité n’est ni une erreur technique ni une correction automatique. Le contrôle fourni de licence compte les répétitions par COUNT(*)-COUNT(DISTINCT licence), et inclut les NULL si présents : cette limite est documentée plutôt que modifiée silencieusement.

### Automatisation préparée

T_PURGE exécute le même bloc que purge_rh.sql ; T_QUALITE celui de qualite_rh.sql ; T_TABLES reprend les trois INSERT OVERWRITE exacts dans une transaction. Création conditionnelle puis ALTER TASK MODIFY AS évitent de recréer les tâches et leurs dépendances. La racine est suspendue avant édition, puis les trois tâches sont laissées suspendues en sortie. Horaire : 05:00 Europe/Paris ; warehouse NYC_TAXI_WH, propriétaire TRANSFORMER. La mesure bloquante est committée avant l’exception. Les scripts de lancement, consultation et suspension sont séparés pour rendre les points de capture explicites.

Suivi filtré sur NYC_TAXI.MARTS et les trois noms, dernier graph_run_group_id et sa tentative : un succès d’une ancienne exécution ne doit pas masquer un échec récent. Exécution demandée ne signifie pas terminée ; attendre les trois SUCCEEDED avant capture. Documentation : [CREATE TASK](https://docs.snowflake.com/en/sql-reference/sql/create-task), [ALTER TASK](https://docs.snowflake.com/en/sql-reference/sql/alter-task), [TASK_HISTORY](https://docs.snowflake.com/en/sql-reference/functions/task_history), consultées le 6 novembre 2026.
