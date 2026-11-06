# Registre du traitement — données du personnel

Document en cours — 5 novembre 2026. Inventaire établi par lecture des en-têtes et des transformations du kit, sans publication de valeurs des CSV. Qualification des colonnes expliquée avec l’étudiant ; relecture finale, décisions de tags et preuves Snowflake à compléter.

## Partie 1 — Inventaire des données personnelles

Une donnée personnelle se rapporte à une personne identifiable : elle peut être une identité, une coordonnée, un attribut professionnel ou une mesure d’activité. Une donnée professionnelle n’est pas exclue de cette définition. Un identifiant interne ne rend pas un fichier anonyme. Une agrégation par chauffeur reste personnelle.

Source : RGPD du 27 avril 2016, article 4 §1, [texte publié par la CNIL](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre1), consulté le 5 novembre 2026. La qualification ci-dessous est l’application de cette définition au schéma fourni.

Les 18 colonnes des deux fichiers sont personnelles dans leur contexte, car chaque ligne concerne un chauffeur identifiable. Les attributs d’activité ne sont pas tous des identifiants : ils décrivent la personne identifiée par les autres colonnes.

### `drivers.csv`

| Colonne | Qualification : personnelle dans ce fichier | Tag DONNEE_PERSONNELLE envisagé | Besoin métier / utilisation |
|---|---|---|---|
| `driver_id` | Identifiant indirect, relié à la fiche RH et aux services. | identifiant_interne | Tous les rôles métier : jointures et comptages. |
| `first_name` | Identité ; prénom directement nominatif, parfois insuffisant seul. | nom | Paie ; responsable du dépôt concerné pour organiser le travail. Masqué pour ANALYSTE. |
| `last_name` | Identité ; nom directement nominatif, homonymies possibles. | nom | Paie ; responsable du dépôt concerné. Masqué pour ANALYSTE. |
| `email` | Coordonnée permettant de contacter et souvent identifier le chauffeur. | email | Paie selon le contrat. Masqué pour responsables et ANALYSTE. |
| `phone` | Coordonnée permettant de contacter le chauffeur. | telephone | Paie ; responsable du dépôt concerné. Masqué pour ANALYSTE. |
| `birth_date` | Attribut personnel pouvant contribuer à une identification indirecte. | date_naissance | Paie : date complète ; ANALYSTE : année seulement ; responsables : masquée. |
| `tlc_license_number` | Identifiant officiel du chauffeur ; son caractère éventuellement public ne change pas sa nature personnelle. | identifiant_officiel | Paie selon le contrat. Masqué pour responsables et ANALYSTE. |
| `depot` | Affectation professionnelle du chauffeur, identifiable par driver_id. | Écart : aucune valeur adaptée | Tous les métiers dans leur périmètre ; clé de filtrage des responsables. |
| `hire_date` | Date du parcours professionnel d’un chauffeur identifiable. | Écart : aucune valeur adaptée | Gestion du personnel ; calcul d’ancienneté. Accès selon matrice et choix de minimisation à préciser. |
| `end_date` | Date du parcours professionnel et indication de départ. | Écart : aucune valeur adaptée | Gestion du personnel ; déclenchement de la purge ; distinction actifs et anciens. Accès à préciser. |

### `driver_shifts.csv`

| Colonne | Qualification : personnelle dans ce fichier | Tag DONNEE_PERSONNELLE envisagé | Besoin métier / utilisation |
|---|---|---|---|
| `shift_id` | Identifiant du service relié à un chauffeur par driver_id. | identifiant_interne | Pipeline : dédoublonnage et traçabilité. Pas exposé dans le mart mensuel fourni. |
| `driver_id` | Identifiant indirect reliant activité et personne. | identifiant_interne | Tous les rôles métier : jointures et activité par chauffeur. |
| `shift_date` | Date d’activité d’un chauffeur identifiable. | Écart : aucune valeur adaptée | Pipeline : regroupement par mois ; analyses temporelles. |
| `depot` | Lieu d’affectation ou d’activité d’un chauffeur identifiable. | Écart : aucune valeur adaptée | Analyse par garage et filtrage des responsables. |
| `start_hour` | Horaire de travail d’un chauffeur identifiable. | Écart : aucune valeur adaptée | Organisation des services ; besoin de conservation à justifier. Pas exposé dans le mart fourni. |
| `hours_worked` | Mesure du travail d’un chauffeur identifiable. | Écart : aucune valeur adaptée | Paie, pilotage des dépôts, analyse d’activité ; agrégée par chauffeur et mois. |
| `trips_count` | Mesure de l’activité d’un chauffeur identifiable. | Écart : aucune valeur adaptée | Pilotage et analyse ; agrégée par chauffeur et mois. |
| `revenue_usd` | Mesure économique de l’activité d’un chauffeur identifiable. | Écart : aucune valeur adaptée | Pilotage et analyse ; agrégée par chauffeur et mois. |

### Où les données sont-elles copiées ?

Lecture des fichiers SQL fournis ; aucune exécution des transformations n’est encore attestée. Noms des tables préfixés par NYC_TAXI.

| Source | Étape intermédiaire | Destination et forme |
|---|---|---|
| Les dix colonnes de drivers.csv | RAW.DRIVERS puis STAGING.STG_RH__DRIVERS | MARTS.DIM_DRIVER : les dix colonnes ; email normalisé, téléphone nettoyé, dépôt normalisé et dates typées dans STAGING. |
| hire_date, end_date | STAGING.STG_RH__DRIVERS | MARTS.DIM_DRIVER.tenure_years : ancienneté calculée. |
| end_date | STAGING.STG_RH__DRIVERS | MARTS.DIM_DRIVER.is_active : statut calculé. |
| first_name, last_name | RAW.DRIVERS → STAGING → MARTS.DIM_DRIVER | MARTS.MART_DRIVER_MONTHLY.driver_name : concaténation des noms ; personnelle aussi. |
| Les huit colonnes de driver_shifts.csv | RAW.DRIVER_SHIFTS puis STAGING.STG_RH__DRIVER_SHIFTS | Vue de typage et dédoublonnage par shift_id. |
| driver_shifts.driver_id, depot | STAGING.STG_RH__DRIVER_SHIFTS | MARTS.MART_DRIVER_MONTHLY : driver_id et depot. |
| shift_date | STAGING.STG_RH__DRIVER_SHIFTS | MARTS.MART_DRIVER_MONTHLY.activity_month : mois d’activité. |
| hours_worked, trips_count, revenue_usd | STAGING.STG_RH__DRIVER_SHIFTS | MARTS.MART_DRIVER_MONTHLY : sommes par chauffeur, mois et dépôt. |
| Les services identifiés par shift_id | STAGING.STG_RH__DRIVER_SHIFTS | MARTS.MART_DRIVER_MONTHLY.nb_shifts : comptage des services, sans copie de shift_id. |
| start_hour | RAW puis STAGING | Non repris dans MARTS par les SQL fournis. |

MARTS.DIM_DEPOT est un référentiel de garages sans lien vers un chauffeur dans ses propres lignes : pas de donnée personnelle dans son contenu fourni. À distinguer de depot dans une fiche chauffeur.

Les colonnes techniques _source_file et _loaded_at sont ajoutées par le chargement, puis renommées source_file et loaded_at dans STAGING, sans copie dans MARTS. Leur contenu attendu décrit l’ingestion et ne désigne pas un chauffeur à lui seul ; il reste attaché à des lignes personnelles et soumis aux contrôles d’accès. Ne pas inclure de noms de personnes dans les noms de fichiers.

### Couverture des tags et limites du contrat

Les valeurs permises de DONNEE_PERSONNELLE décrivent l’identité et les identifiants, mais pas explicitement les dates professionnelles, l’affectation ni les mesures d’activité. Le même écart concerne les attributs calculés is_active, tenure_years, activity_month, nb_shifts et les agrégats par chauffeur. driver_name relève de nom.

La qualification juridique et le tag technique sont distincts : une colonne n’est pas non personnelle parce qu’aucune étiquette prévue ne lui correspond. Décision après relecture du 6 novembre 2026 : conserver les valeurs imposées et signaler la couverture impossible sans étiquette trompeuse. Aucun élargissement de taxonomie retenu. L’écart reste explicite dans VEILLE.md, le README et V_CATALOGUE ; les protections et les tests doivent couvrir ces colonnes malgré cette limite de classement.

### Ce qui a surpris

Le dépôt de rattachement et les données d’activité sont personnels dans les lignes des chauffeurs. Les agrégations mensuelles restent personnelles puisqu’elles conservent driver_id. L’identité existe aussi sous forme calculée dans driver_name : oublier cette copie laisserait une voie d’identification.

---

## Partie 2 — Fiche de registre (jour 3)

Le registre des activités de traitement décrit ce qu'une organisation fait des données personnelles qu'elle détient. Cette fiche en est une version réduite, limitée à ce qu'un Data Engineer peut renseigner et prouver. La trame complète est celle de la CNIL (lien dans les ressources).

Chaque réponse de la colonne de droite doit pouvoir être vérifiée dans l'entrepôt : indiquez la requête ou le fichier qui le prouve.

### Le traitement

| Rubrique | Réponse |
|---|---|
| Nom du traitement | Gouvernance des données du personnel et des services de Hudson Cab |
| Finalité : à quoi servent ces données | Gestion du personnel, besoins de la paie, organisation des dépôts et analyse de l’activité ; périmètre et bases légales à détailler par usage. |
| Personnes concernées | Chauffeurs des dépôts Bronx, Brooklyn et Queens ; données fictives traitées pédagogiquement comme un fichier réel. |
| Service responsable des données | Hudson Cab Europe, selon le pouvoir de décision décrit par le brief ; interlocuteur opérationnel RH à préciser. |

### Les données

| Catégorie de données | Colonnes concernées | Tables où elles se trouvent |
|---|---|---|
| Identité | driver_id, first_name, last_name, birth_date, birth_year, tlc_license_number, driver_name calculé | RAW.DRIVERS ; MARTS.DIM_DRIVER ; identifiant et nom calculé dans MART_DRIVER_MONTHLY ; driver_id dans RAW.DRIVER_SHIFTS |
| Coordonnées | email, phone | RAW.DRIVERS, MARTS.DIM_DRIVER |
| Vie professionnelle | depot lié au chauffeur, hire_date, end_date, is_active, tenure_years ; services, dates et mesures d’activité reliées à driver_id | RAW.DRIVERS, RAW.DRIVER_SHIFTS, MARTS.DIM_DRIVER, MARTS.MART_DRIVER_MONTHLY ; vues STAGING dérivées |

### Qui y accède

| Rôle | Ce qu'il voit | Pourquoi il en a besoin | Preuve (requête ou test) |
|---|---|---|---|
| RH_PAIE | Tous les dépôts, valeurs en clair | Paie | Cahier ACCES.md et capture 03a |
| RESP_DEPOT_QUEENS / RESP_DEPOT_BRONX | Leur dépôt, identité et téléphone selon matrice ; autres attributs protégés | Organisation du dépôt | ACCES.md, mapping et tests par rôle |
| ANALYSTE | Tous les dépôts, identifiant interne et année de naissance ; identité masquée | Analyse d’activité | Captures 03c et 15 |
| TRANSFORMER | Sources et copies en clair | Chargement, purge, qualité, reconstruction | Captures 13 à 23 et tests de fidélité |
| GOUVERNANCE / ACCOUNTADMIN | Gouvernance : pas de SELECT RH ; administrateur : zéro ligne dans les tests | Configuration ou audit des métadonnées | ACCES.md et captures 03d, 15 ; ne constitue pas une protection contre la modification malveillante des règles par un administrateur |

### Combien de temps

| Règle | Comment elle est appliquée | Preuve |
|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | Purge exécutée : 400→354 chauffeurs ; aucune copie expirée dans les quatre tables, première preuve vérifiée sur capture. | rh/purge_rh.sql, gouvernance/tests/05_preuve_purge.sql et capture 12_purge_et_time_travel.png |
| R2 : pas de restauration au-delà de 1 jour | DATA_RETENTION_TIME_IN_DAYS=1 observé sur les quatre tables ; Fail-safe distinct ; disparition après 24 h non testée. | rh/conservation_rh.sql et capture 11_retention_un_jour.png |
| R3 : pas de fichier sur le stage | PURGE=TRUE dans le COPY ; stage vide rapporté, dernière vérification LIST encore à conserver. | rh/chargement_rh_2_copier.sql |

Délai réel entre l'exécution de la purge et la disparition définitive d'une donnée dans Snowflake, en tenant compte de Time Travel et de Fail-safe : Un jour de Time Travel puis sept jours de Fail-safe sur les tables permanentes : succession nominale de huit jours, sans garantie d’effacement physique à heure fixe. Les requêtes longues, copies externes et fichiers locaux doivent aussi être pris en compte.

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | Audit préparé sur sept jours ; résultat encore à vérifier, latence possible de trois heures. | 06_audit.sql (rôles, capture publique), 06b_audit_detail_prive.sql (comptes, consultation privée) |
| Sait-on quand une donnée est fausse ? | Trois règles exécutées : 4 licences et 7 emails en ALERTE, 25 services orphelins sous le seuil bloquant 50 ; elles ne garantissent pas toute l’exactitude. | rh/qualite_rh.sql et futurs résultats QUALITE_RESULTATS |
| Que se passe-t-il si le rôle des outils est compromis ? | TRANSFORMER dispose des données en clair et possède les tables : compromission critique, les règles actuelles ne suffisent pas contre leur propriétaire malveillant. Suspendre les tâches, retirer les habilitations du compte compromis, renouveler ses accès et examiner les journaux. | Privilèges d’installation, mapping TRANSFORMER et politiques ; réponse à incident proposée, non exercée |

### Limites connues

Ce que votre mise en œuvre ne couvre pas : deux ou trois lignes, sans détour.

## Évolution préparée — année de naissance

Migration 01_annee_naissance.sql préparée, non exécutée : ajout de MARTS.DIM_DRIVER.birth_year depuis YEAR(birth_date). C’est une donnée personnelle calculée, tag date_naissance, destinée à ANALYSTE et RH_PAIE ; la date complète reste masquée à ANALYSTE. Cette copie doit aussi disparaître lors de la purge. Le SQL de reconstruction et la fiche du catalogue ont été adaptés ; aucune table recréée.

## Protections préparées — 6 novembre 2026

Retour de Lucas : migration birth_year exécutée. Test rouge sur capture avant politique : accès encore trop large pour ANALYSTE. Masquage et filtre par dépôt désormais préparés dans les scripts 03/04, non confirmés exécutés ; les preuves finales d’accès et de purge restent à compléter. Les colonnes sans tag de nature adapté reçoivent aussi des protections directes, sauf depot, protégé par la règle de lignes et le périmètre de privilèges.

## Preuves d’accès disponibles — 6 novembre 2026

Les captures 03a à 03d attestent la démo agrégée DIM_DRIVER pour RH_PAIE, Queens, ANALYSTE et ACCOUNTADMIN. Elles ne prouvent pas encore tous les accès du registre : GOUVERNANCE, Bronx, RAW/STAGING, activité mensuelle, autres colonnes et stabilité à vérifier dans le cahier. Pas de donnée nominative dans ces preuves.

## État des preuves de conservation

Scripts préparés le 6 novembre 2026, non exécutés. Aucun test de disparition après 24 heures ni d’effacement physique final attesté. La preuve Time Travel utilisera un instant enregistré avant purge et ne publiera que des comptes. Référence du kit pour cette date : 46 chauffeurs expirés, sans service de ces chauffeurs dans la période de services fournie.

## Preuves de conservation reçues

Le 6 novembre 2026 : capture 11 avec quatre rétentions à un jour ; capture 12 avec 354 chauffeurs courants, 400 dans l’état antérieur et zéro copie expirée. Ces preuves couvrent l’exécution et le paramétrage, pas un effacement physique observé après huit jours. La première capture reste la preuve de référence même après rejeu de la purge.

## Qualité observée et automatisation préparée

Capture 06 des résultats manuels vérifiée. Tâches quotidiennes préparées, non exécutées à ce stade ; les preuves planifiées et du blocage restent à ajouter. Aucune correction des valeurs RH déduite du simple contrôle qualité.

## Première chaîne quotidienne réussie — 6 novembre 2026

Captures 13_creation_taches_transformer.png et 14_execution_chaine_reussie.png conservées et copies vérifiées. Trois tâches détenues par TRANSFORMER, dépendances purge → qualité → reconstruction ; trois SUCCEEDED du même groupe, de 14:52:31 à 14:52:42 (+0100). Exécution manuelle de la chaîne configurée à 05:00 Europe/Paris ; déclenchement horaire non encore observé. Résultats qualité issus de la tâche, maintien des protections après tâche et blocage restent à contrôler.

### Validation après la première chaîne — 6 novembre 2026

Captures docs/15_controles_apres_taches.png et docs/16_qualite_par_tache.png : 18 contrôles verts après reconstruction et trois nouvelles mesures qualité conformes (7 emails, 4 licences, 25 services orphelins, seuil bloquant 50). Les preuves confirment le maintien des protections après tâche. Capture du graphe visuel avec exécution réussie encore attendue (BRIEF.md, livrable 2), puis test bloquant et audit.

### Preuves du graphe et préparation du blocage

Captures 17_graphe_taches.png et 18_historique_t_purge.png rangées : structure du graphe et succès de la racine ; capture 14 pour les trois succès. Test de seuil temporaire à 0 dans snowflake/gouvernance/tests/07_preparer_blocage.sql, restauration à 50 dans 08_retablir_seuil.sql. Chaque modification se fait hors exécution active, racine suspendue ; le lancement et le suivi utilisent les scripts rh dédiés. Capturer l’échec attendu et ses mesures avant restauration, puis la chaîne normale réussie. Test de blocage non encore attesté ; audit et lignage restent à réaliser.

### Blocage qualité prouvé — 6 novembre 2026

Captures 19 à 21 conservées : succès du graphe complet initial, puis échec qualité au seuil temporaire 0, reconstruction non démarrée et mesures conservées (25 services orphelins / 0 / ALERTE). T05 validé par les résultats observés. Le rétablissement du seuil normal à 50 et la nouvelle chaîne réussie restent à confirmer avec tests/08_retablir_seuil.sql puis les scripts rh de lancement, suivi et consultation qualité. Audit et lignage restent à réaliser.

### Seuil rétabli et audit préparé — 6 novembre 2026

Captures 22 et 23 : retour à trois tâches réussies et seuil 50, test T06 validé. Exécuter snowflake/gouvernance/06_audit.sql avec ACCOUNTADMIN : capture publique des rôles, objets, colonnes et comptes de requêtes. 06b_audit_detail_prive.sql permet l’identification des comptes utilisateurs uniquement dans Snowflake ; ne pas publier sa sortie. Ces deux scripts sont préparés, non exécutés. Audit limité aux sept derniers jours, délai ACCESS_HISTORY jusqu’à trois heures ; une lecture référencée ne démontre pas que la valeur était affichée en clair. Documentation : https://docs.snowflake.com/en/sql-reference/account-usage/access_history et https://docs.snowflake.com/en/sql-reference/account-usage/query_history (consultées le 6 novembre 2026).

Capture restante : sous TRANSFORMER, Catalog → Explorer → NYC_TAXI → MARTS → MART_DRIVER_MONTHLY → Lineage. Déplier les sources amont pour présenter le chemin RAW → STAGING → MARTS ; graphe automatique à observer avant de le déclarer validé. Documentation : https://docs.snowflake.com/en/user-guide/ui-snowsight-lineage.
