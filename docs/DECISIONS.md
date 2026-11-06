# Décisions de gouvernance

## D01 — Couvrir toutes les données personnelles dans le catalogue

Date : 6 novembre 2026. État : choix de conception retenu, migration préparée ; validation Snowflake en attente.

### Problème

L’inventaire qualifie 39 colonnes personnelles dans quatre tables RAW/MARTS. Les six catégories initiales de DONNEE_PERSONNELLE en classent 19, mais pas les vingt attributs professionnels et d’activité restants. Le brief exige leur couverture complète. Une valeur telle que identifiant_interne serait trompeuse pour une recette ou une date de contrat.

### Décision

Conserver les trois tags et les six catégories existantes, puis ajouter deux valeurs à DONNEE_PERSONNELLE :

| Nouvelle valeur | Sens | Colonnes |
|---|---|---|
| donnee_professionnelle | Situation et parcours professionnels | depot dans les quatre tables, hire_date/end_date dans RAW et la dimension, is_active et tenure_years dans la dimension : dix affectations |
| activite | Événement ou mesure d’activité rattaché au chauffeur | shift_date, start_hour, hours_worked, trips_count, revenue_usd dans les services ; activity_month, nb_shifts, hours_worked, trips_count, revenue_usd dans le mensuel : dix affectations |

Il s’agit d’une extension explicite de la section 3 du contrat initial, pas d’une valeur déjà prévue par celui-ci. Le document de référence est conservé intact pour permettre la comparaison. L’objectif est de satisfaire la couverture C20 et de conserver une classification fidèle ; aucune approbation externe ni validation juridique n’est affirmée.

### Conséquence sur le masquage

DEPOT porte une donnée personnelle dans une ligne chauffeur et sert de signature à RAP_DEPOT. Snowflake ne permet pas de mettre une même colonne dans les signatures d’un masque et d’une politique de lignes. Un masque automatique lié au tag VARCHAR se propagerait à DEPOT après classification : on retire donc les trois associations automatiques tag/masque, après avoir attaché les mêmes masques directement aux 35 colonnes à protéger. DEPOT reste tagué, lisible uniquement dans le périmètre autorisé et protégé par RAP_DEPOT.

La politique textuelle continue de consulter la valeur de DONNEE_PERSONNELLE pour distinguer identité, coordonnées et identifiant. Les autres politiques conservent leurs corps et leurs rôles ; aucun droit ou périmètre métier n’est élargi. La classification et les attaches des politiques sont explicites et rejouables.

### Mise en œuvre et preuve

- 01_gouvernance.sql définit les huit catégories pour une installation neuve ou existante.
- 03_masquage.sql crée les mêmes politiques, pose les 35 masques directs puis retire les anciens liens automatiques présents.
- Les quatre fiches personnelles du catalogue rétablissent les 39 affectations ; les métadonnées d’ingestion et DIM_DEPOT ne sont pas classées personnelles.
- 05_completer_tags.sql est une migration autonome, avec une copie exacte du nouveau masquage et des quatre fiches ; aucune tâche n’est relancée.
- tests/12_couverture_tags.sql précède la migration dans Git (ffeb584). Attendu : 10/8/13/8 colonnes conformes, zéro écart ; 21 colonnes personnelles dans les 25 lignes du catalogue métier.
- tests/10_recette_complete.sql doit encore produire 69 conformités sur huit rôles après migration. Les captures 27/28 prouvent les recettes avant extension, pas cette nouvelle version.

Sources techniques consultées le 6 novembre 2026 : [ALTER TAG](https://docs.snowflake.com/en/sql-reference/sql/alter-tag), [masquage lié aux tags et limites avec les politiques de lignes](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies), [POLICY_REFERENCES](https://docs.snowflake.com/en/sql-reference/functions/policy_references), [lecture du tag dans une politique](https://docs.snowflake.com/en/sql-reference/functions/system_get_tag_on_current_column).
