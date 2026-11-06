# Suivi du projet Hudson Cab

État au 6 novembre 2026. Lucas exécute les scripts dans Snowflake ; l’assistant inspecte les résultats fournis et maintient les fichiers. Un résultat déclaré reste distingué d’une preuve observée.

## Validations

| Élément | État |
|---|---|
| Dépôt, Enterprise AWS Paris, installation | Déclarés opérationnels ; données sources exclues de Git |
| Veille | Cinq fiches, trois sources officielles et fréquence ; inscription CNIL observée. Suivis EDPB/EUR-Lex proposés, non configurés |
| Inventaire et registre | Sources et dérivations documentées ; preuves renseignées |
| Intégration | Volumes initiaux contrôlés ; stage vide observé ; rejeu immédiat du COPY non formellement prouvé |
| Catalogue | Descriptions contrôlées, 25 colonnes dans la vue métier ; limite de couverture de tags signalée, C20 non intégralement validé |
| Accès | Démo de quatre rôles observée ; tests détaillés conformes déclarés par Lucas, voir ACCES.md |
| Mapping | Trois étapes observées après purge : 143/365, 249/655, 143/365 ; état initial restauré |
| Conservation | 46 chauffeurs purgés, 354 restants ; historique 400 accessible, rétention un jour sur quatre tables |
| Qualité et tâches | Trois règles ; trois tâches réussies sous TRANSFORMER ; blocage et retour au seuil 50 observés |
| Stabilité | 18 contrôles après tâches OK ; rejeu des scripts de politiques A14 validé, capture 26 |
| Audit et lignage | Captures observées ; consultation nominative privée de l’audit non attestée |

## Captures demandées

| Preuve | Fichier dans docs/ |
|---|---|
| Abonnement de veille | 01_abonnement_veille.png |
| Tags d’une table | 02_tags_dim_driver_avant_correction.png ; couverture limitée explicitée dans le README |
| Même requête avec plusieurs rôles | 03a à 03d_acces_*.png |
| Lignage | 04_lignage.png |
| Graphe et succès d’exécution | 17_graphe_taches.png et 19_succes_graphe_complet.png ; tableau complet 14 |
| Résultats qualité | 06_resultats_qualite_manuels.png, 16 et 23 pour les tâches |
| Audit | 07_audit.png |

Preuves supplémentaires : 08 volumes, 10 test rouge, 11 rétention, 12 purge/Time Travel, 13 propriété des tâches, 15 protections après tâches, 20/21 blocage, 22/23 rétablissement, 24 mapping, 25 stage vide, 26 rejeu des politiques. Les deux CSV du personnel et les résultats nominatifs ne sont pas publiés.

## Avant le rendu

- A14 confirmé : parcours de rejeu 03_masquage.sql puis 04_acces_depot.sql, suivi du test 06_verifier_apres_taches.sql ; capture 26, 18 OK.
- Rejeu immédiat du chargement non attesté : ne pas recharger le fichier historique après purge uniquement pour compléter une capture. Décrire cette limite.
- Tests complémentaires A17-A19 et consultation nominative privée de l’audit non attestés ; aucune réussite inventée.
- Démonstration avec docs/SOUTENANCE.md. Suspendre T_PURGE après la dernière exécution terminée avec rh/suspendre_taches_rh.sql.
- Vérifier les fichiers du dépôt public et les commits ; push à réaliser par Lucas.

## Limites à exposer

Identifiant et agrégats par chauffeur restent personnels. La taxonomie imposée ne couvre pas tous les attributs personnels : écart C20 signalé, masques directs appliqués là où nécessaire. Les cinq ans demandent une justification juridique par finalité ; base active et archive non distinguées. Un jour de Time Travel puis Fail-safe ne signifie pas effacement physique immédiat. TRANSFORMER possède les tables et les administrateurs peuvent modifier les règles. L’horaire quotidien est configuré mais seules des exécutions demandées manuellement ont été observées.
