# Les accès — carte des droits et cahier de tests

Document en cours — 5 novembre 2026. Installation déclarée réussie par l’étudiant ; droits effectifs à vérifier par SHOW GRANTS. Aucun test d’accès exécuté ni résultat vert consigné à ce stade. Les résultats attendus seront écrits avant les politiques.

- **Partie 1, jours 1 et 2** : la carte des droits, complétée au fur et à mesure que vous créez rôles et objets ;
- **Partie 2, jour 2** : le cahier de tests, « attendu » écrit avant les politiques, « obtenu » après.

---

## Partie 1 — Carte des droits

À compléter du jour 1 au jour 2. Dans Snowflake, faire une action demande d'être propriétaire de l'objet ou d'avoir reçu un privilège précis. Cette carte vous évite de chercher, à chaque erreur `Insufficient privileges`, quel droit manque et à qui.

Vérifiez chaque ligne dans la documentation des privilèges (ressources du jour 2), puis avec `SHOW GRANTS TO ROLE …`.

### Qui possède quoi

Le propriétaire d'un objet est le rôle qui l'a créé.

| Objet | Propriétaire |
|---|---|
| Tables de `RAW` et de `MARTS` | le rôle des outils |
| Schéma `GOUVERNANCE` | |
| Tags | |
| Politiques de masquage | |
| Politique d'accès par ligne | |
| Table `ACCES_DEPOT` | |
| Table `QUALITE_RESULTATS` | |
| Vue `V_CATALOGUE` | |

### Qui fait quoi, avec quel droit

| Action | Rôle qui la fait | Privilège nécessaire | Accordé par |
|---|---|---|---|
| Créer un tag | `GOUVERNANCE` | `CREATE TAG` sur le schéma, ou en être propriétaire | `ACCOUNTADMIN` |
| Poser un tag sur une colonne de `DIM_DRIVER` | | | |
| Créer une politique de masquage | | | |
| Attacher une politique de masquage à un tag | | | |
| Ajouter une politique d'accès par ligne à une table | | | |
| Écrire une ligne dans `QUALITE_RESULTATS` | | | |
| Lire `DIM_DRIVER` | | | |
| Exécuter une requête | chaque rôle | | |

### Ce que cette carte permet à un rôle de défaire

Pour chaque rôle qui peut poser ou retirer un tag, ou détacher une politique : que pourrait-il démasquer ? Est-ce acceptable, et qui le surveille ?

---

## Partie 2 — Cahier de tests

Décidez d'abord à quoi ressemble une valeur masquée pour chaque type de colonne (texte, date) et notez-le ici : ______. Puis remplissez en deux temps : la colonne « attendu » **avant** d'écrire les politiques, à partir de la matrice du contrat ; la colonne « obtenu » après, en exécutant la requête avec le rôle indiqué (`USE ROLE ...`).

Un test est vert quand « obtenu » est identique à « attendu ». Un accès refusé (`Object does not exist or not authorized`) est un résultat comme un autre : écrivez-le.

### Lignes visibles

| N° | Rôle | Requête | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|
| 1 | `RH_PAIE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER` | | | |
| 2 | `RESP_DEPOT_QUEENS` | la même | | | |
| 3 | `RESP_DEPOT_QUEENS` | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER` | | | |
| 4 | `RESP_DEPOT_BRONX` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY` | | | |
| 5 | `ANALYSTE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER` | | | |
| 6 | `GOUVERNANCE` | la même | | | |
| 7 | `ACCOUNTADMIN` | la même | | | |
| 8 | `RH_PAIE` | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS` | | | |
| 9 | `ANALYSTE` | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS` | | | |
| 9 bis | `ACCOUNTADMIN` | `SELECT first_name, email FROM NYC_TAXI.RAW.DRIVERS LIMIT 3` | | | |

### Valeurs visibles

Pour le chauffeur `D0003`, la valeur que chaque rôle doit lire dans chaque colonne (ou « colonne absente », ou « ligne invisible »).

| Colonne | `RH_PAIE` | `RESP_DEPOT_QUEENS` | `RESP_DEPOT_BRONX` | `ANALYSTE` |
|---|---|---|---|---|
| nom et prénom | | | | |
| e-mail | | | | |
| téléphone | | | | |
| date de naissance | | | | |
| numéro de licence | | | | |
| `driver_name` dans `MART_DRIVER_MONTHLY` | | | | |

### Le pipeline fonctionne toujours

| N° | Vérification | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|
| 10 | Avec le rôle des outils, après avoir relancé les fichiers SQL : nombre de lignes de `DIM_DRIVER` | | | |
| 11 | Avec `RH_PAIE` : l'e-mail de `D0003` est toujours une vraie adresse | | | |
| 12 | Les politiques sont toujours attachées après la relance (requête de la section 7 du contrat) | | | |

Ajoutez vos propres tests : un cahier qui ne contient que des tests verts dès le premier essai n'a probablement pas cherché les cas limites.

## Préparation du socle de gouvernance — 6 novembre 2026

Source : snowflake/gouvernance/01_gouvernance.sql, préparé mais pas encore exécuté. Les droits ci-dessous sont des droits prévus ; les vérifier avec SHOW GRANTS avant de les déclarer effectifs.

| Rôle | Objet | Droit prévu | But |
|---|---|---|---|
| GOUVERNANCE | Base NYC_TAXI, warehouse NYC_TAXI_WH, schémas RAW et MARTS | USAGE | Désigner les objets et exécuter ses opérations, sans SELECT sur les données RH. |
| GOUVERNANCE | Schéma GOUVERNANCE | OWNERSHIP | Créer tags, politiques et tables de gouvernance ; ne confère pas la propriété des tables RH. |
| GOUVERNANCE | Compte | APPLY MASKING POLICY et APPLY ROW ACCESS POLICY | Attacher les politiques aux tables RH détenues par TRANSFORMER. |
| TRANSFORMER | Schéma GOUVERNANCE | USAGE, CREATE VIEW | Accéder aux objets autorisés et créer le futur catalogue. |
| TRANSFORMER | Chacun des trois tags | APPLY | Cataloguer les tables qu’il possède. |
| TRANSFORMER | QUALITE_RESULTATS | INSERT, SELECT | Enregistrer et consulter les contrôles. |

GOUVERNANCE crée et possède les tags et QUALITE_RESULTATS. Le fait de posséder des métadonnées et résultats de qualité n’autorise pas à lire les fiches personnelles. Aucun rôle métier créé à cette étape. L’attribution du rôle à l’utilisateur courant permet de l’endosser ; les privilèges sur les données restent portés par les rôles.

Vérification négative prévue après le socle : avec GOUVERNANCE, rôles secondaires désactivés, SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER doit être refusé. Résultat obtenu : non exécuté.

### Retour d’exécution du socle

Le 6 novembre 2026, Lucas confirme que 01_gouvernance.sql s’exécute et affiche les trois tags. Cette déclaration ne remplace pas le test négatif de lecture RH par GOUVERNANCE ni les tests métier. Le catalogue est créé par TRANSFORMER ; ses futurs droits métier restent à attribuer et à vérifier.
