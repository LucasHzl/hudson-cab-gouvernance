# Suivi et index des preuves

État au 6 novembre 2026. Les captures et résultats consignés sont distingués des scripts sans résultat d’exécution. Les critères détaillés figurent dans [CONTROLE_RENDU.md](CONTROLE_RENDU.md).

## Index

| Preuve | Fichier(s) dans docs/ | Résultat |
|---|---|---|
| Abonnement CNIL | 01_abonnement_veille.png | Inscription enregistrée |
| Tags initiaux | 02_tags_dim_driver_avant_correction.png | Historique de la couverture partielle ; couverture complète observée ensuite sur 29 et 31a/31b |
| Même requête par rôle | 03a_acces_rh_paie.png, 03b_acces_queens.png, 03c_acces_analyste.png, 03d_acces_accountadmin.png | Comparaison des lectures |
| Lignage | 04_lignage.png | Sources dimension et STAGING services |
| Qualité | 06_resultats_qualite_manuels.png, 16_qualite_par_tache.png, 23_qualite_retablie_seuil_50.png | Mesures et rétablissement |
| Audit | 07_audit.png | Quatre métiers, TRANSFORMER et ACCOUNTADMIN ; 13 groupes rôle/type |
| Volumes initiaux | 08_volumes_initialisation.png | STAGING 25 933, dépôts 3, dimension 400, mensuel 914 |
| Catalogue initial | 09_catalogue_avant_correction.csv | Métadonnées, 24 colonnes avant birth_year ; aucune donnée du personnel |
| Test rouge | 10_test_analyste_avant_politiques.png | Exposition avant protection |
| Conservation | 11_retention_un_jour.png | Quatre rétentions à un jour |
| Purge et Time Travel | 12_purge_et_time_travel.png | 354 courants, 400 historiques, zéro copie expirée |
| Tâches | 13_creation_taches_transformer.png, 14_execution_chaine_reussie.png, 17_graphe_taches.png, 18_historique_t_purge.png, 19_succes_graphe_complet.png | Propriété, structure, succès de la racine puis du graphe |
| Après reconstruction | 15_controles_apres_taches.png | 18 contrôles OK |
| Blocage | 20_blocage_qualite_chaine.png, 21_mesures_qualite_seuil_zero.png | Qualité FAILED, reconstruction non démarrée ; mesures durables |
| Rétablissement | 22_chaine_retablie_seuil_50.png, 23_qualite_retablie_seuil_50.png | Trois succès, seuil final 50 |
| Mapping | 24_mapping_apres_purge.png | 143/365 → 249/655 → 143/365 |
| Stage | 25_stage_vide.png | Zéro fichier |
| Après rejeu des règles | 26_rejeu_politiques_18_controles.png | 18 contrôles OK |
| Recette complète | 27_recette_complete_69_controles.png | 69/69 conformes, huit rôles, zéro échec avant D01 |
| Rejeu du chargement | 28_rejeu_chargement.png | Six contrôles OK après deux rejeux, stage vide |
| Couverture complète | 29_couverture_complete_tags.png | 39 colonnes conformes, zéro écart ; 21 personnelles dans le catalogue |
| Après classification | 30_recette_apres_classification.png | 69/69 conformes sur huit rôles, zéro échec |
| Tags détaillés actuels | 31a_tags_dim_driver_complets.png, 31b_tags_dim_driver_complets.png | Les 13 colonnes de DIM_DRIVER portent leur classification |

Toutes les catégories de captures explicitement demandées sont présentes. Les images sont conservées sans modification de leur contenu. Les références avant et après purge sont datées, pas interchangeables.

## État final et extension de classification

Les recettes 10 et 11 sont prouvées par les captures 27/28 ; la suspension de la racine est consignée sans capture dédiée. Les règles initiales, le chargement et la matrice d’accès ont leurs preuves. La consultation nominative de l’audit reste privée, sans sortie personnelle publiée.

Décision D01 : compléter la classification avec donnee_professionnelle et activite. L’extension est documentée, le contrat initial est conservé. Migration exécutée par 05_completer_tags.sql ; couverture observée 39 colonnes personnelles et zéro manque, capture 29. Pour éviter de masquer DEPOT, les masques sont attachés directement avant retrait des anciens liens automatiques du tag.

Tests 12 et 10 exécutés après migration : cinq lignes de couverture OK et 69 conformités, captures 29/30. Les tags détaillés de DIM_DRIVER sont conservés dans 31a/31b. Les 17 critères hors bonus ont leurs pièces et preuves, sous réserve de l’évaluation de l’extension D01 et des limites explicites. Aucune tâche n’est activée par ces fichiers ; suspension finale consignée. Seule la publication des derniers commits reste à vérifier après push.

Le minimum hors bonus de trois règles qualité est implémenté. Les bonus ne sont ni requis ni présentés comme réalisés.
