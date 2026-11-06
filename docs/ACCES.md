# Accès — carte des droits et cahier de tests

Version du 6 novembre 2026. Les attentes initiales ont précédé les politiques (commit aafdccd). Le test rouge puis les résultats protégés sont conservés. Les captures montrent uniquement des agrégats et des métadonnées ; aucune valeur personnelle n’est publiée.

## 1. Propriété et droits

| Objet | Propriétaire |
|---|---|
| Tables RAW/MARTS, vues STAGING, trois tâches | TRANSFORMER |
| Schéma GOUVERNANCE, trois tags, politiques, ACCES_DEPOT, QUALITE_RESULTATS | GOUVERNANCE |
| V_CATALOGUE | TRANSFORMER |

| Action | Rôle | Privilège nécessaire | Accordé par / script |
|---|---|---|---|
| Créer un tag ou une politique | GOUVERNANCE | Propriété du schéma ou CREATE TAG / CREATE MASKING POLICY / CREATE ROW ACCESS POLICY | ACCOUNTADMIN, 01_gouvernance.sql |
| Poser les tags sur les colonnes | TRANSFORMER | Propriété de la table et APPLY sur chaque tag | GOUVERNANCE pour APPLY, 01_gouvernance.sql |
| Associer un masque au tag | GOUVERNANCE | Propriété du tag et APPLY MASKING POLICY | ACCOUNTADMIN pour APPLY, 01_gouvernance.sql |
| Retirer les anciennes associations tag/masque | GOUVERNANCE | Propriété du tag et APPLY MASKING POLICY | Migration D01 ; masques directs posés avant retrait |
| Attacher une politique de lignes à une table | GOUVERNANCE | APPLY ROW ACCESS POLICY sur le compte | ACCOUNTADMIN, 01_gouvernance.sql |
| Modifier le mapping rôle/dépôt | GOUVERNANCE | Propriété de ACCES_DEPOT | Création dans 04_acces_depot.sql |
| Écrire les mesures qualité | TRANSFORMER | INSERT sur QUALITE_RESULTATS et USAGE du schéma | GOUVERNANCE, 01_gouvernance.sql |
| Lire une table métier | Les quatre rôles métier | USAGE base/schéma, SELECT sur table, USAGE warehouse | ACCOUNTADMIN, 02_roles_metier.sql ; filtres et masques ensuite appliqués |
| Lire le catalogue | Les quatre rôles métier | USAGE base/schéma et SELECT sur vues de GOUVERNANCE | ACCOUNTADMIN, 02_roles_metier.sql |
| Exécuter les tâches | TRANSFORMER | OWNERSHIP des tâches, EXECUTE TASK sur compte, USAGE warehouse et privilèges des traitements | Installation et propriété des objets |
| Exécuter une requête | Chaque rôle autorisé | USAGE warehouse, droits sur les objets et contenants | Scripts d’installation et de rôles |

Les rôles métier n’ont aucun accès RAW/STAGING ni écriture métier. ANALYSTE lit toutes les tables/vues présentes et futures de MARTS ; les autres métiers lisent les trois tables du domaine. Tous disposent des vues de catalogue. Les attributions à l’utilisateur courant servent à tester les rôles ; les règles métier ne mentionnent jamais un compte individuel.

### Pouvoir de défaire une règle

TRANSFORMER possède les tables et peut retirer certaines attaches. GOUVERNANCE peut changer les politiques et le mapping ; l’administrateur peut changer les habilitations. Le dispositif prouve la restriction des lectures avec les règles actuelles, pas une résistance à la reconfiguration malveillante par un propriétaire. Réserver ces rôles aux opérations nécessaires, examiner les changements et auditer les accès. Les masques doivent laisser le pipeline lire en clair pour éviter d’écrire des masques dans les données.

## 2. Matrice des valeurs et des lignes

| Colonne ou famille | RH_PAIE | Responsables | ANALYSTE | TRANSFORMER |
|---|---|---|---|---|
| driver_id | Clair | Clair, leur dépôt | Clair | Clair |
| depot | Tous | Leur dépôt | Tous | Tous |
| first_name, last_name, driver_name | Clair | Clair, leur dépôt | [MASQUE] | Clair |
| phone | Clair | Clair, leur dépôt | [MASQUE] | Clair |
| email, tlc_license_number | Clair | [MASQUE] | [MASQUE] | Clair |
| birth_date | Date complète | NULL | NULL | Date complète |
| birth_year | Année | NULL | Année | Année |
| hire_date, end_date | Clair | NULL | NULL | Clair |
| is_active, tenure_years | Clair | NULL | Clair | Clair |
| activity_month, nb_shifts, hours_worked, trips_count, revenue_usd | Clair | NULL | Clair | Clair |

NULL source reste NULL. Masquer une date par NULL évite de fabriquer une fausse date. birth_year est calculée séparément. Les attributs d’activité visibles pour ANALYSTE permettent l’analyse prévue sans révéler directement l’identité. Pour les responsables, la lecture stricte du contrat ne laisse que identité/téléphone, driver_id et clé de périmètre ; les mesures sont masquées.

GOUVERNANCE reçoit un refus d’autorisation sur les données RH ; ACCOUNTADMIN et SYSADMIN obtiennent zéro ligne sur les quatre tables personnelles par absence du mapping. DIM_DEPOT est un référentiel sans données personnelles : trois lignes visibles à tous les métiers, sans filtre. Les rôles secondaires sont désactivés dans les parcours de test.

### Chauffeur témoin D0003

Le témoin suit exactement cette matrice : paie en clair, responsable de son dépôt avec identité/téléphone, autre responsable sans ligne, analyste avec identifiant interne/année et identité masquée. Si le témoin est purgé, tous les métiers obtiennent zéro ligne. Les vérifications de valeurs se font dans Snowflake ; leurs sorties publiques sont des indicateurs de conformité, pas les noms, coordonnées ou licences du témoin. La recette complète compare toutes les lignes au périmètre de référence, au lieu de dépendre d’un seul témoin.

## 3. Comptages et preuves d’accès

| Périmètre | Avant purge : chauffeurs / mensuel | Après purge : chauffeurs / mensuel |
|---|---|---|
| Queens | 161 / 365 | 143 / 365 |
| Bronx | 122 / 290 | 106 / 290, déduit de la différence 249−143 du mapping |
| Brooklyn | 117 / 259 | 105 / 259, différence au total 354 |
| Total | 400 / 914 | 354 / 914 |

Les volumes après purge évoluent avec la date ; les tests 02 et 10 calculent leurs références avec TRANSFORMER.

| Test | Attendu | Résultat consigné / preuve | État |
|---|---|---|---|
| A00, avant politiques | Identifier l’exposition excessive de l’analyste | 400 chauffeurs, zéro prénom masqué, 400 dates complètes, capture 10 | ROUGE initial prouvé |
| A01, RH_PAIE | Tous dépôts en clair | Démo 400/0/400/400, capture 03a ; tests détaillés du fichier 01 consignés conformes | Conforme, preuve agrégée |
| A02, Queens | Queens seulement, identité/téléphone autorisés | Démo 161/0/0/0, capture 03b ; mapping final 143/365, capture 24 | Conforme, preuve agrégée |
| A03, Bronx | Bronx seulement, identité/téléphone autorisés | Test du fichier 01 consigné conforme ; pas de capture dédiée | Prouvé par la recette 10, captures 27 puis 30 après D01 |
| A04, ANALYSTE | Tous dépôts, identité masquée, année seule | Démo 400/400/0/400, capture 03c ; après purge 354 prénoms masqués, capture 26 | Conforme, preuve agrégée |
| A05, GOUVERNANCE/DIM_DRIVER | Refus d’autorisation | Test du fichier 01 consigné conforme | Prouvé par la recette 10, captures 27 puis 30 après D01 |
| A06, ACCOUNTADMIN | Aucune ligne DIM_DRIVER et RAW.DRIVER_SHIFTS | Compteurs 0/0 consignés ; zéro DIM_DRIVER sur captures 03d et 26 | Conforme, preuve agrégée |
| A07-A08, métiers sur RAW | Refus d’autorisation | Test du fichier 01 consigné conforme | Prouvé par la recette 10, captures 27 puis 30 après D01 |
| A09, référentiel | Trois dépôts pour les quatre métiers | Tests du fichier 01 consignés conformes | Prouvé par la recette 10, captures 27 puis 30 après D01 |
| A10-A11, masques complémentaires | Matrice complète, mensuel compris | Tests du fichier 01 consignés conformes ; captures partielles 03 | Prouvé par la recette 10, captures 27 puis 30 après D01 |
| A12, catalogue | 25 colonnes/3 tables, descriptions présentes, accès métier | Test du fichier 01 consigné conforme ; 25 lignes accessibles, capture 26 | Conforme, preuve agrégée |
| A13, fidélité pipeline | Emails non masqués et égaux à STAGING | Zéro masque et zéro écart, capture 26 | Prouvé |
| A14, rejeu des politiques | Pas de perte des règles | 18 contrôles OK après rejeu 03/04, capture 26 | Prouvé |
| A15, reconstruction | Protections et descriptions maintenues | 18 contrôles OK après tâches, capture 15 | Prouvé sur les contrôles exécutés |
| A16, extension par mapping | Ajouter Bronx sans modifier la politique, puis restaurer | 143/365 → 249/655 → 143/365, trois OK, capture 24 | Prouvé |
| A17-A20, contrôles additionnels | SYSADMIN zéro, administrateur RAW zéro, refus GOUVERNANCE/RAW/STAGING, bon rôle actif | Capture 27 : 69 assertions conformes, huit rôles, zéro échec | Prouvé |

## 4. Conservation, qualité et tâches

| Test | Attendu | Obtenu / preuve | État |
|---|---|---|---|
| R01 | Quatre rétentions à un jour | Quatre lignes à 1, capture 11 | Prouvé |
| R02-R03 | Copies expirées supprimées, 400 → 354 | Zéro copie expirée et 354 chauffeurs, capture 12 | Prouvé |
| R04 | État avant purge encore lisible dans Time Travel | 400 historiques contre 354 courants, capture 12 | Prouvé |
| R05 | Pas de restauration Time Travel après un jour | Paramètre 1 observé ; essai à 24 h non réalisé | Paramètre prouvé, délai réel non testé |
| R06 | Stage vide | Zéro fichier, capture 25 | Prouvé |
| Q01 | licence_unique, seuil 0, avertissement | 4 / 0 / ALERTE, captures 06/16/23 | Prouvé |
| Q02 | email_valide, seuil 0, avertissement | 7 / 0 / ALERTE, mêmes captures | Prouvé |
| Q03 | service_rattache, seuil 50, bloquant au-delà | 25 / 50 / OK, capture 23 | Prouvé |
| T01-T02 | Propriétaire TRANSFORMER, ordre purge/qualité/reconstruction, trois succès | Captures 13/14/17/19/22 | Prouvé |
| T03-T04 | Mesures ajoutées et protections conservées | Mesures récentes et 18 contrôles OK, captures 15/16/26 | Prouvé |
| T05 | Au seuil temporaire 0, échec qualité sans reconstruction et journal durable | SUCCEEDED / FAILED / NON_DEMARREE, 25/0/ALERTE, captures 20/21 | Prouvé |
| T06 | Rétablir 50, nouvelle chaîne réussie | Trois succès et 25/50/OK, captures 22/23 | Prouvé |
| AU01 | Rôles et colonnes référencées sur sept jours | 13 groupes rôle/type, capture 07 | Prouvé |
| AU02 | Comptes utilisateurs consultables sans publication | 06b_audit_detail_prive.sql | Script prêt, consultation privée non consignée |
| L01 | Lignage du mensuel | DIM_DRIVER + STAGING services vers mensuel, capture 04 | Prouvé |
| I01 | Deux rejeux du chargement, stage vide, contenus RAW inchangés | Capture 28 : six assertions OK après deux rejeux | Prouvé |

Les mesures sont enregistrées avant l’exception bloquante. Les deux alertes non bloquantes ne sont pas des échecs techniques. L’audit ne démontre pas à lui seul une visibilité en clair ; les tests de lecture apportent cette distinction. ACCOUNTADMIN peut référencer la table tout en obtenant zéro ligne.

## 5. Recette finale renforcée

10_recette_complete.sql compare sous chaque rôle les périmètres et les attributs autorisés à leurs références TRANSFORMER, vérifie tous les masques de la dimension et du mensuel, les quatre accès au référentiel/catalogue, 22 refus RAW/STAGING et GOUVERNANCE, et les lectures administrateur/SYSADMIN. Les comparaisons d’empreintes restent internes à la session ; seules les conformités sortent. Les objets sont interrogés sous TRANSFORMER avant les tests de refus pour ne pas prendre une table absente pour une protection correcte.

11_rejeu_chargement.sql réexécute deux fois le bloc exact du chargement, avec stage vide exigé. Volumes et empreintes complètes des deux RAW doivent rester identiques ; aucun fichier historique n’est redéposé. Cela prouve le rejeu après purge du stage, pas le traitement d’une nouvelle livraison complète.

Les scripts 01 et 04 conservent les références initiales avant purge. Après purge, utiliser les recettes dynamiques 02, 06, 10 et 11. Les tests non exécutés restent identifiés ; aucune validation n’est déduite de la seule présence d’un script.

## Recettes finales observées et extension de classification

[Capture 27](27_recette_complete_69_controles.png) : 69/69 contrôles conformes, zéro échec sur huit rôles (7 administrateur, 11 analyste, 7 gouvernance, 11 Bronx, 11 Queens, 9 paie, 7 SYSADMIN, 6 TRANSFORMER). Elle consolide les tests détaillés A01-A12 et A17-A20. [Capture 28](28_rejeu_chargement.png) : six contrôles OK, volumes et contenus RAW identiques après deux rejeux ; stage vide. Suspension de la racine consignée après ces opérations, sans capture dédiée.

Avant extension : couverture attendue 39 colonnes personnelles sur quatre tables, zéro écart et 21 colonnes personnelles taguées dans le catalogue métier (25 colonnes au total). Attentes dans tests/12_couverture_tags.sql. Après migration, rejouer également tests/10_recette_complete.sql : 69 contrôles toujours attendus conformes, sans changement de la matrice des accès. Les résultats antérieurs ne valent pas validation de la migration.

## Nouvelle classification — contrôles validés

La décision D01 ajoute deux catégories et remplace les anciens liens automatiques tag/masque par des attaches directes. La politique textuelle continue de lire le tag ; les quatre DEPOT sont classés sans masque et restent filtrés. Aucun rôle, privilège ni corps métier des masques n’est élargi. Les 35 colonnes masquées restent réparties 9/7/12/7 sur les quatre tables.

Migration autonome 05_completer_tags.sql exécutée. Test 12 : cinq lignes OK, 13/8/10/8 colonnes conformes pour les quatre tables, soit 39, et 21 colonnes personnelles dans le catalogue métier (capture 29). Test 10 : 69 conformités, huit rôles, zéro échec après migration (capture 30). Les vues 31a/31b montrent les 13 colonnes de DIM_DRIVER, leurs descriptions et tags. La capture 27 conserve l’état de référence avant évolution ; 30 prouve l’état actuel.

## Bilan de couverture après migration

| Contrôle | Attendu | Obtenu | État |
|---|---|---|---|
| CLASS01, DIM_DRIVER | 13 colonnes personnelles taguées et décrites | 13/13, zéro écart, capture 29 ; vue détaillée 31a/31b | Prouvé |
| CLASS02, mensuel | 8 colonnes personnelles taguées et décrites | 8/8, zéro écart, capture 29 | Prouvé |
| CLASS03, RAW.DRIVERS | 10 colonnes personnelles taguées et décrites | 10/10, zéro écart, capture 29 | Prouvé |
| CLASS04, RAW.DRIVER_SHIFTS | 8 colonnes personnelles taguées et décrites | 8/8, zéro écart, capture 29 | Prouvé |
| CLASS05, catalogue métier | 21 colonnes personnelles dans 25 lignes, aucun manque | 21/21, zéro écart, capture 29 | Prouvé |
| CLASS06, non-régression | 69 contrôles conformes sur huit rôles | 69/69, zéro échec, capture 30 | Prouvé |

Aucune réactivation des tâches n’est incluse dans la migration ni ces deux tests. Les dates et volumes de référence avant purge restent historiques ; les recettes dynamiques représentent l’état actuel. L’extension des deux valeurs est justifiée dans DECISIONS.md et n’est pas présentée comme une approbation externe.
