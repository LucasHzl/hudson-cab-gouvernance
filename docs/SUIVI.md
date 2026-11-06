# Suivi du projet Hudson Cab

Mis à jour le 6 novembre 2026.

## Avancement

Les validations ci-dessous sont déclarées par l'étudiant, sauf mention contraire. Les volumes STAGING/MARTS ont été inspectés sur une capture fournie ; aucune connexion directe de l’assistant à Snowflake.

- [x] Dépôt GitHub public créé : https://github.com/LucasHzl/hudson-cab-gouvernance
- [x] Kit placé à la racine du dépôt local.
- [x] CSV RH et environnement virtuel ignorés par Git ; sorties Git partagées dans la conversation avant déplacement du kit, puis architecture confirmée par l'étudiant.
- [x] Compte Snowflake Enterprise d'essai, AWS Paris, déclaré par l'étudiant.
- [x] Script 00_installation.sql exécuté avec ACCOUNTADMIN ; présence de RAW, STAGING et MARTS confirmée par l'étudiant.
- [x] Note rédigée : cinq fiches, trois sources officielles nommées, fréquence proposée, inscription CNIL prouvée et confrontation au contrat. Relecture finale et suivis complémentaires encore à faire.
- [x] Inventaire des deux fichiers rédigé et lignage SQL documenté.
- [ ] Registre du traitement : compléter les preuves et limites après implémentation.
- [ ] Chargement rejouable, volumes contrôlés et stage vide.
- [x] Catalogue : 24 colonnes métier décrites, observées dans l’export ; fiches RAW préparées.
- [ ] Catalogue : vérifier RAW et lecture métier ; couverture des tags limitée par la taxonomie imposée, écart documenté.
- [x] Matrice et tests attendus écrits AVANT les politiques ; SQL de tests prêt, exécution à faire.
- [x] Rôles et politiques exécutés ; démo agrégée de quatre rôles conforme et prouvée.
- [ ] Cahier complet : Bronx, autres colonnes, mensuel, refus d’accès, catalogue, mapping et rejeu à vérifier.
- [x] Purge dans les quatre tables et rétention un jour observées sur captures ; lecture historique avant purge prouvée.
- [ ] Qualité et chaîne de tâches ; preuve du blocage.
- [ ] Audit, lignage et vérification du maintien des protections.
- [ ] README : exécution, décisions, écarts et limites ; vérification du contenu avant publication.

## Captures explicitement demandées par le guide

À ranger dans docs/ du dépôt, avec des noms explicites. Éviter toute donnée personnelle ou secret dans les captures publiques ; privilégier métadonnées, comptes, statuts et résultats masqués.

| Preuve | Nom proposé | État |
|---|---|---|
| Abonnement réel à l'outil de veille | 01_abonnement_veille.png | Capture vérifiée : inscription CNIL enregistrée, 6 novembre 2026 |
| Tags d'une table dans Snowsight | 02_tags_dim_driver_avant_correction.png | Reçue ; couverture incomplète de la taxonomie signalée |
| Même requête avec deux rôles, comparaison lisible | 03a à 03d_acces_*.png | Quatre captures vérifiées : démo conforme |
| Lignage de MART_DRIVER_MONTHLY | 04_lignage.png | À faire |
| Graphe des tâches et exécution réussie | 05_taches_succes.png | À faire |
| Résultats de QUALITE_RESULTATS | 06_resultats_qualite_manuels.png | Trois règles et mesures manuelles vérifiées ; mesures par tâches à vérifier |
| Résultat de la requête d'audit | 07_audit.png | À faire |

La comparaison de deux rôles peut nécessiter deux images. Elle ne remplace pas le cahier de tests de tous les rôles, dont ACCOUNTADMIN et GOUVERNANCE.

Preuves supplémentaires utiles : volumes et stage vide ; purge avant/après et Time Travel ; échec du contrôle bloquant sans reconstruction ; politiques, tags et descriptions conservés après pipeline. Captures ou sorties de requêtes documentées selon le cas.

Source : GUIDE_BRIEF_GOUVERNANCE.md, résultats des jours 1, 2 et 3 et étapes de validation : https://github.com/gsoulat/formation-data-IA/blob/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance/starter-kit/GUIDE_BRIEF_GOUVERNANCE.md

## Décisions et notions établies

- TRANSFORMER exécute le pipeline selon le principe du moindre privilège.
- Dans le scénario, Hudson Cab Europe décide de l'utilisation des données : qualification de responsable du traitement à documenter dans VEILLE.md.
- Application du RGPD : article 3 §1, traitement dans le cadre de l'établissement européen. L'hébergement à Paris est distinct de ce critère.
- Un identifiant interne ne rend pas les données anonymes ; driver_id reste une donnée personnelle.
- La qualification de l'entité new-yorkaise et les dispositions contractuelles des prestataires restent à préciser ; ne pas inventer de contrat signé.
- Les dates, résultats, captures et abonnements non constatés restent marqués à faire ; aucun test ne sera déclaré réussi par anticipation.

## Mise à jour des livrables

Dépôt local identifié et modèles lus le 5 novembre 2026. README.md initialisé ; droit applicable ajouté dans docs/VEILLE.md ; contexte du traitement ajouté dans docs/REGISTRE.md ; état des tests précisé dans docs/ACCES.md. Inventaire, dispositif de veille, fiches, comparaison et tests restent à compléter. Exclusion effective des deux CSV vérifiée localement avec git check-ignore ; aucun CSV suivi selon git ls-files.

## Dernière séance — inventaire

En-têtes des deux CSV lus localement sans afficher de lignes de données. Trois colonnes de drivers.csv documentées : driver_id, birth_date, depot. Affectation au dépôt : donnée personnelle dans une fiche chauffeur ; écart de couverture des valeurs de tags signalé dans le registre et le README. Reste de l’inventaire à examiner.

## Inventaire complété — 5 novembre 2026

Les 10 en-têtes de drivers.csv et les 8 en-têtes de driver_shifts.csv ont été confrontés au registre : couverture exhaustive vérifiée. Le lignage a été lu dans les SQL STAGING et MARTS fournis. Les données d’activité liées à un chauffeur sont personnelles ; driver_name et les agrégats mensuels ont été inclus. Aucune valeur de ligne CSV publiée. Couverture insuffisante des valeurs de tags signalée dans le README et VEILLE.md ; stratégie à décider. Cela ne valide ni les protections ni le chargement Snowflake.

## Veille rédigée — 5 novembre 2026

Cinq fiches sourcées, proposition de suivi de trois sources réglementaires officielles et confrontation du contrat (accès, R1-R3, catalogue, scripts et huit règles qualité) ajoutées. Référentiel RH CNIL du 2 avril 2026 repéré ; périmètre droit du travail français explicité. Écarts : durée uniforme non justifiée, absence de distinction base active / archive, couverture des tags ; limite Fail-safe documentée. README actualisé. Abonnement réel, outil choisi, capture et relecture restent à faire. Aucun dispositif déclaré actif ni conformité juridique attestée.

## Capture de veille reçue — 6 novembre 2026

Lucas fournit les captures dans la conversation ; l’assistant les copie sous des noms explicites dans docs/ et met à jour les références et statuts. Original conservé. La capture 01_abonnement_veille.png montre l’enregistrement réussi de l’inscription à la lettre CNIL. Aucune adresse personnelle ni secret visible. L’image copiée a été comparée à l’original par empreinte SHA-256. VEILLE.md et README mis à jour. La première réception et les suivis complémentaires restent non constatés ; ne pas déduire de cette preuve que toutes les sources sont suivies automatiquement.

## Chargement RAW — 6 novembre 2026

Lucas confirme le résultat de la requête de vérification : TRANSFORMER, 400 chauffeurs, 25 951 services. Le message « Query produced no results » a été expliqué comme résultat vide de LIST après purge du stage. Statut : chargement confirmé par retour utilisateur, pas de capture reçue ; stage à documenter visuellement et seconde exécution à consigner. Transformations STAGING/MARTS pas encore confirmées. README complété : ordre des scripts, format, stage, COPY INTO, PURGE et limites de rejouabilité.

## Volumes vérifiés et gouvernance préparée — 6 novembre 2026

Capture rangée dans docs/08_volumes_initialisation.png, copie identique vérifiée. Lecture : STAGING_SERVICES 25 933, DIM_DEPOT 3, DIM_DRIVER 400, MART_DRIVER_MONTHLY 914. Volumes conformes avant purge ; cela ne prouve pas encore la qualité de chaque valeur ni le maintien de protections après pipeline. RAW reste confirmé par retour utilisateur, stage et rejouabilité à documenter.

Script snowflake/gouvernance/01_gouvernance.sql préparé d’après les exemples et les syntaxes officielles CREATE TAG et GRANT OWNERSHIP. Aucun accès métier ouvert ni politique créée. Exécution et droits réels à confirmer par SHOW GRANTS et SHOW TAGS ; trois tags attendus. Les six valeurs imposées sont conservées, leur couverture incomplète reste signalée.

## Socle confirmé, catalogue préparé — 6 novembre 2026

Lucas confirme le succès de 01_gouvernance.sql et le résultat attendu des tags. Vérification négative du SELECT RH par GOUVERNANCE à faire. Cinq fiches de catalogue créées, 46 descriptions de colonnes prévues, tags table et tags de nature compatibles avec les valeurs du contrat. V_CATALOGUE et vérification créées ; 24 lignes MARTS attendues. Aucun script de catalogue déclaré exécuté. Exigence de tags sur toute donnée personnelle non satisfaite à ce stade : ECART_TAG_CONTRAT explicite dans la vue et le README, à arbitrer avant clôture.

## Catalogue observé — 6 novembre 2026

Export 09_catalogue_avant_correction.csv vérifié : 24 lignes (DIM_DEPOT 4, DIM_DRIVER 12, MART_DRIVER_MONTHLY 8), zéro description vide, 11 colonnes personnelles métier sans tag. La capture 02_tags_dim_driver_avant_correction.png confirme les tags d’identité et l’absence sur des attributs professionnels. Preuves copiées à l’identique ; ces métadonnées ne contiennent pas de valeurs du fichier RH.

Correction distincte préparée : snowflake/gouvernance/01b_proposition_completer_tags.sql. Proposition d’ajout de donnee_professionnelle et activite aux six valeurs, puis affectation sur les 20 colonnes manquantes RAW et MARTS. Après exécution : 38 colonnes personnelles RAW/MARTS attendues, toutes taguées, dont 20 colonnes métier. Statut historique : proposition non exécutée, désormais retirée après relecture des consignes. Contrat non modifié ; extension non déclarée conforme à sa liste fermée.

## Relecture et décision finale sur les tags — 6 novembre 2026

Brief, contrat, guide, ressources, note de présentation et modèles relus. Le contrat n’est pas à réécrire ; le guide demande de signaler les écarts. L’extension proposée par l’assistant est donc retirée des scripts livrables et archivée hors du dépôt. La liste de six valeurs demeure ; aucun reclassement trompeur de l’activité n’est effectué. README, VEILLE et REGISTRE alignés sur cette décision.

La couverture intégrale du tag et le respect sémantique des six valeurs sont incompatibles pour l’inventaire large : C20 ne doit pas être déclaré entièrement validé. Cette limite documentaire n’empêche pas de réaliser les autres exigences : droits et tests avant politiques, filtrage par table de correspondance, purge complète, trois contrôles dont service_rattache, chaîne de tâches, audit et preuves de maintien des protections.

Les entrées précédentes sont historiques ; la décision présente remplace la proposition d’extension. Rien à relancer dans Snowflake pour cette décision.

## Versionnement et préparation des accès — 6 novembre 2026

Commit local 03fdf0e : kit, veille, catalogue et preuves. Contrôle de contenu avant ajout : aucun CSV RH suivi, pas de clé ou motif de secret détecté, aucune valeur d’email/téléphone/licence du CSV dans les textes candidats. Les captures ne montrent que confirmations et métadonnées.

Cahier de tests attendu rédigé avant toute politique, résultats tous non exécutés. Références de dépôts calculées localement : chauffeurs Queens 161 / Bronx 122 / Brooklyn 117 ; lignes mensuelles 365 / 290 / 259. Script 02_roles_metier.sql et migration birth_year préparés, non exécutés. DIM_DRIVER passe à 13 colonnes, le catalogue métier à 25 après migration ; les anciennes captures restent historiques. Prochain contrôle : exécuter 02 puis 01_annee_naissance et transmettre seulement le résultat agrégé.

## Test rouge constaté, politiques préparées — 6 novembre 2026

Capture 10_test_analyste_avant_politiques.png rangée et copie vérifiée : 400 / 0 / 400. Rôles métier et migration confirmés par Lucas ; aucune preuve de masquage après protection à ce stade. Scripts 03_masquage.sql et 04_acces_depot.sql créés après les tests committés dans aafdccd. Deux scripts de démonstration complètent le cahier : mapping temporaire et comparaison de quatre rôles. Syntaxes vérifiées contre les documents officiels ; pas de connexion Snowflake de l’assistant, validation d’exécution encore nécessaire.

## Point d’avancement et correctif — 6 novembre 2026

Estimation indicative : environ 45 % du projet, selon le travail exécuté et prouvé, pas une note ni un calcul officiel des compétences. Veille/inventaire et pipeline initial avancés ; accès en validation ; conservation, qualité, tâches, audit et démonstration finale encore à réaliser.

Erreur de compilation signalée dans 03_masquage.sql sur l’attache groupée au tag. Correction en trois ALTER TAG distincts, conservation de FORCE pour le rejeu. Aucune politique ni attache existante supprimée. Résultat d’exécution du correctif à attendre avant de continuer le cahier de tests.

## Quatre preuves d’accès reçues — 6 novembre 2026

03a RH_PAIE : 400 / 0 / 400 / 400 ; 03b Queens : 161 / 0 / 0 / 0 ; 03c ANALYSTE : 400 / 400 / 0 / 400 ; 03d ACCOUNTADMIN : 0 / 0 / 0 / 0. Captures renommées et rangées, copies identiques vérifiées. Résultats D01-D04 de la démo verts dans ACCES.md. Tests plus larges A01/A02/A04/A06/A11 indiqués partiels ; pas de conclusion sur les attributs non affichés ou sur MART_DRIVER_MONTHLY. Prochaines validations : cahier complet, mapping et reconstruction avant purge.

## Clarification des compteurs de tests — 6 novembre 2026

Fichier 01 déclaré conforme par Lucas, exception de lecture sur le bloc zéro/zéro à confirmer. Fichier 02 : 655 lignes mensuelles rapportées, compteur chauffeur non vu car résultat séparé. Deux paires de SELECT regroupées en un tableau par contrôle. Pas de changement de politique ni nouvelle habilitation. Résultats détaillés marqués déclarés ou partiels dans ACCES.md ; restauration du mapping, reconstruction et vérifications après rejeu encore à confirmer.

## Compteurs clarifiés, dernières vérifications avant purge — 6 novembre 2026

ACCOUNTADMIN 0/0 et Queens restauré 161/365 confirmés par Lucas. Extension du mapping pas encore validée. Test 02 simplifié en un tableau final avec trois étapes ; nouveau test 04 pour reconstruction des trois tables métier et 12 contrôles synthétiques. Scripts préparés, exécution à confirmer ; aucune purge réalisée.

### Correctif du test de reconstruction — 6 novembre 2026

Erreur signalée sur les mots « vide » et « la » : deux commentaires avaient été extraits comme instructions lors de la préparation du script 04. Les deux lignes sont retirées ; les trois INSERT OVERWRITE INTO ont été comparés intégralement aux fichiers rh/marts correspondants, avec recherche ancrée en début de ligne SQL. Ce contrôle local ne confirme pas l’exécution Snowflake. Script corrigé à relancer entièrement ; aucune table, politique ou tag supprimé. Le test de reconstruction reste en attente de résultat.

## Reconstruction confirmée, conservation préparée — 6 novembre 2026

Lucas confirme le succès du script 04 corrigé : douze contrôles attendus OK. Statut déclaré, sans capture dédiée. Test de mapping étendu pas encore attesté. conservation_rh.sql, purge_rh.sql et tests/05_preuve_purge.sql créés ; attentes et références locales consignées avant exécution. La purge touche les quatre tables, pas seulement RAW.DRIVERS ; Time Travel réglé séparément à un jour. Prochaine étape : vérifier le mapping avant purge, exécuter conservation puis preuve de purge et transmettre les résultats agrégés.

## Preuves de conservation et préparation qualité — 6 novembre 2026

Captures 11_retention_un_jour.png et 12_purge_et_time_travel.png rangées à l’identique : rétention un jour sur quatre tables, sept contrôles de purge OK dont historique 400 et courant 354. Rejeu de la preuve : nouvel instant de référence, donc historique 354 normal ; première preuve conservée. Consigne de capture désormais annoncée avant toute exécution et inscrite en tête des scripts.

Qualité préparée : trois requêtes scalaires dont la licence fournie, plus qualite_rh.sql qui ajoute trois mesures et bloque uniquement service_rattache > 50, après commit des résultats. Attendus locaux 4 / 7 / 25, non encore observés dans Snowflake. Tâches et audit restent à réaliser.

## Qualité confirmée et chaîne préparée — 6 novembre 2026

Capture 06_resultats_qualite_manuels.png rangée et comparée à l’original : email_valide 7 ALERTE, licence_unique 4 ALERTE, service_rattache 25/50 OK, même instant de mesure. Les trois requêtes sont opérationnelles manuellement. Chaîne T_PURGE → T_QUALITE → T_TABLES préparée sous TRANSFORMER, horaire Paris, création suspendue ; lancement, suivi, lecture qualité et suspension séparés. Test après tâches de 18 contrôles prêt, non exécuté. Le suivi groupe les tâches de la même exécution. Blocage, audit et lignage encore à réaliser.

## Première chaîne quotidienne réussie — 6 novembre 2026

Captures 13_creation_taches_transformer.png et 14_execution_chaine_reussie.png conservées et copies vérifiées. Trois tâches détenues par TRANSFORMER, dépendances purge → qualité → reconstruction ; trois SUCCEEDED du même groupe, de 14:52:31 à 14:52:42 (+0100). Exécution manuelle de la chaîne configurée à 05:00 Europe/Paris ; déclenchement horaire non encore observé. Résultats qualité issus de la tâche, maintien des protections après tâche et blocage restent à contrôler.

### Validation après la première chaîne — 6 novembre 2026

Captures docs/15_controles_apres_taches.png et docs/16_qualite_par_tache.png : 18 contrôles verts après reconstruction et trois nouvelles mesures qualité conformes (7 emails, 4 licences, 25 services orphelins, seuil bloquant 50). Les preuves confirment le maintien des protections après tâche. Capture du graphe visuel avec exécution réussie encore attendue (BRIEF.md, livrable 2), puis test bloquant et audit.

### Preuves du graphe et préparation du blocage

Captures 17_graphe_taches.png et 18_historique_t_purge.png rangées : structure du graphe et succès de la racine ; capture 14 pour les trois succès. Test de seuil temporaire à 0 dans snowflake/gouvernance/tests/07_preparer_blocage.sql, restauration à 50 dans 08_retablir_seuil.sql. Chaque modification se fait hors exécution active, racine suspendue ; le lancement et le suivi utilisent les scripts rh dédiés. Capturer l’échec attendu et ses mesures avant restauration, puis la chaîne normale réussie. Test de blocage non encore attesté ; audit et lignage restent à réaliser.
