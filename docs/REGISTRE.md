# Registre du traitement — données du personnel

Mis à jour le 6 novembre 2026. Inventaire des sources et dérivations, registre et preuves techniques renseignés à partir des scripts et résultats fournis par Lucas. Aucune valeur personnelle des CSV publiée ; les décisions juridiques restent à faire valider par le responsable du traitement.

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

Copies identifiées dans les SQL fournis et transformations exécutées ; volumes et lignage observés sur captures. Noms des tables préfixés par NYC_TAXI.

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
| R3 : pas de fichier sur le stage | PURGE=TRUE dans le COPY ; stage vide observé par LIST, compteur à zéro. | rh/chargement_rh_2_copier.sql, tests/09_stage_vide.sql, capture 25_stage_vide.png |

Délai réel entre l'exécution de la purge et la disparition définitive d'une donnée dans Snowflake, en tenant compte de Time Travel et de Fail-safe : Un jour de Time Travel puis sept jours de Fail-safe sur les tables permanentes : succession nominale de huit jours, sans garantie d’effacement physique à heure fixe. Les requêtes longues, copies externes et fichiers locaux doivent aussi être pris en compte.

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | Audit exécuté sur sept jours : quatre métiers, TRANSFORMER et ACCOUNTADMIN référencent DIM_DRIVER ; résultat sans preuve de valeurs visibles en clair. Identification des comptes possible via le complément privé, non attestée. | Capture 07_audit.png ; 06_audit.sql et 06b_audit_detail_prive.sql ; délai possible de trois heures |
| Sait-on quand une donnée est fausse ? | Trois règles exécutées : 4 licences et 7 emails en ALERTE, 25 services orphelins sous le seuil bloquant 50 ; elles ne garantissent pas toute l’exactitude. | rh/qualite_rh.sql et captures 16, 21, 23 |
| Que se passe-t-il si le rôle des outils est compromis ? | TRANSFORMER dispose des données en clair et possède les tables : compromission critique, les règles actuelles ne suffisent pas contre leur propriétaire malveillant. Suspendre les tâches, retirer les habilitations du compte compromis, renouveler ses accès et examiner les journaux. | Privilèges d’installation, mapping TRANSFORMER et politiques ; réponse à incident proposée, non exercée |

### Limites connues

La taxonomie imposée ne couvre pas toutes les catégories personnelles : inventaire et protections en place, écart C20 explicite. La durée uniforme de cinq ans nécessite une justification par finalité et une décision sur l’archivage. Time Travel et Fail-safe empêchent d’assimiler la purge à un effacement physique immédiat ; copies externes hors périmètre. Les rôles administratifs et le propriétaire des tables peuvent reconfigurer le système : les tests ne constituent pas une protection contre un administrateur malveillant.


## Preuves de mise en œuvre

| Sujet | Résultat observé | Preuve |
|---|---|---|
| Année de naissance | birth_year calculée et taguée, date complète masquée à ANALYSTE | Migration 01_annee_naissance.sql ; captures 03c et 15 |
| Accès | Paie, Queens, analyste et administrateur comparés ; autres tests déclarés distingués dans ACCES.md | Captures 03a à 03d |
| Extension du périmètre | Queens 143/365 → Queens+Bronx 249/655 → Queens 143/365 | Capture 24 |
| Reconstruction | 18 contrôles OK après tâches ; masques, filtres, descriptions et conservation maintenus | Capture 15 |
| Chaîne quotidienne | Trois tâches sous TRANSFORMER, horaire 05:00 Europe/Paris ; lancement manuel réussi | Captures 13, 17, 19, 22 ; départ automatique à l’horaire non observé |
| Blocage qualité | Seuil temporaire 0 : 25 anomalies, qualité FAILED, reconstruction non démarrée ; mesures durables | Captures 20 et 21 |
| Rétablissement | Seuil 50, trois tâches réussies ; 7 emails et 4 licences en ALERTE, 25 services sous le seuil | Captures 22 et 23 |
| Audit | Jointure des historiques sur query_id, quatre métiers et deux rôles techniques, colonnes référencées | Capture 07 ; utilisateurs consultables en privé, consultation nominative non attestée |
| Lignage | DIM_DRIVER et STAGING.STG_RH__DRIVER_SHIFTS alimentent le mensuel | Capture 04 |
| Stage | Zéro fichier | Capture 25 |

Une colonne référencée dans l’audit ne prouve pas une valeur visible en clair. La dépendance V_CATALOGUE visible dans le lignage ne constitue pas une preuve de copie de valeurs personnelles. Rejeu des politiques validé par la capture 26, avec 18 contrôles OK. Rejeu immédiat du chargement et contrôles additionnels non exécutés restent indiqués dans ACCES.md et SUIVI.md.
