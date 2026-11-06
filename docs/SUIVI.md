# Suivi et index des preuves

État au 6 novembre 2026. Les captures et résultats consignés sont distingués des scripts sans résultat d’exécution. Les critères détaillés figurent dans [CONTROLE_RENDU.md](CONTROLE_RENDU.md).

## Index

| Preuve | Fichier(s) dans docs/ | Résultat |
|---|---|---|
| Abonnement CNIL | 01_abonnement_veille.png | Inscription enregistrée |
| Tags | 02_tags_dim_driver_avant_correction.png | Catégories d’identité posées ; écart de taxonomie identifié |
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

Toutes les catégories de captures explicitement demandées sont présentes. Les images sont conservées sans modification de leur contenu. Les références avant et après purge sont datées, pas interchangeables.

## Dernières validations ouvertes

- Recette 10_recette_complete.sql : 69 assertions, huit rôles, dont 22 refus et matrice des deux tables métier ; résultat attendu, non encore exécuté.
- Recette 11_rejeu_chargement.sql : six assertions, deux rejeux avec stage vide ; contrôle du nouveau garde-fou, non encore exécuté.
- Couverture complète du tag DONNEE_PERSONNELLE : écart C20 non levé, pas de catégorie adaptée pour vingt attributs sur RAW/MARTS.
- Consultation nominative de l’audit : script fourni pour une lecture privée ; résultat nominatif non conservé dans le dépôt public.
- Après la dernière démonstration : suspendre la racine avec rh/suspendre_taches_rh.sql. La suspension effective doit être vérifiée dans son résultat.

Le minimum hors bonus de trois règles qualité est implémenté. Les bonus ne sont ni requis ni présentés comme réalisés.
