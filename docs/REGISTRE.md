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
| Identité | | |
| Coordonnées | | |
| Vie professionnelle | | |

### Qui y accède

| Rôle | Ce qu'il voit | Pourquoi il en a besoin | Preuve (requête ou test) |
|---|---|---|---|
| | | | |

### Combien de temps

| Règle | Comment elle est appliquée | Preuve |
|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | | |
| R2 : pas de restauration au-delà de 1 jour | | |
| R3 : pas de fichier sur le stage | | |

Délai réel entre l'exécution de la purge et la disparition définitive d'une donnée dans Snowflake, en tenant compte de Time Travel et de Fail-safe : ______ jours.

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | | |
| Sait-on quand une donnée est fausse ? | | |
| Que se passe-t-il si le rôle des outils est compromis ? | | |

### Limites connues

Ce que votre mise en œuvre ne couvre pas : deux ou trois lignes, sans détour.

## Évolution préparée — année de naissance

Migration 01_annee_naissance.sql préparée, non exécutée : ajout de MARTS.DIM_DRIVER.birth_year depuis YEAR(birth_date). C’est une donnée personnelle calculée, tag date_naissance, destinée à ANALYSTE et RH_PAIE ; la date complète reste masquée à ANALYSTE. Cette copie doit aussi disparaître lors de la purge. Le SQL de reconstruction et la fiche du catalogue ont été adaptés ; aucune table recréée.

## Protections préparées — 6 novembre 2026

Retour de Lucas : migration birth_year exécutée. Test rouge sur capture avant politique : accès encore trop large pour ANALYSTE. Masquage et filtre par dépôt désormais préparés dans les scripts 03/04, non confirmés exécutés ; les preuves finales d’accès et de purge restent à compléter. Les colonnes sans tag de nature adapté reçoivent aussi des protections directes, sauf depot, protégé par la règle de lignes et le périmètre de privilèges.

## Preuves d’accès disponibles — 6 novembre 2026

Les captures 03a à 03d attestent la démo agrégée DIM_DRIVER pour RH_PAIE, Queens, ANALYSTE et ACCOUNTADMIN. Elles ne prouvent pas encore tous les accès du registre : GOUVERNANCE, Bronx, RAW/STAGING, activité mensuelle, autres colonnes et stabilité à vérifier dans le cahier. Pas de donnée nominative dans ces preuves.
