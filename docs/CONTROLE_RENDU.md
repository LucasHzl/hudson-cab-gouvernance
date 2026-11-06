# Contrôle du rendu — hors bonus

Contrôle du 6 novembre 2026, contre BRIEF.md, CONTRAT_GOUVERNANCE.md, GUIDE_BRIEF_GOUVERNANCE.md et les trois trames de documents du kit. Deux passes : exigences/réponses, puis cohérence des scripts, liens, preuves et contenu public. Une case cochée signifie que la pièce ou la preuve existe ; elle ne remplace pas l’évaluation du jury.

## Critères de performance

| Référence | Attendu | État et preuve |
|---|---|---|
| C4.1 | Droit applicable et article précis | [x] VEILLE §1, RGPD 3 §1, 4 §7 ; cinq fiches sourcées |
| C4.2 | Trois sources officielles, fréquence, outil en place | [x] CNIL/EDPB/EUR-Lex, revue hebdomadaire définie et abonnement CNIL prouvé, capture 01 |
| C4.3 | Au moins quatre fiches, sources/dates/impact | [x] Cinq fiches dans VEILLE §3 |
| C4.4 | Chaque règle confrontée aux textes ; écarts dans README | [x] Tableau VEILLE §4 et limites du README ; huit règles qualité incluses |
| C19.1 | Deux CSV chargés, format/stage/COPY expliqués, stage vide | [x] Scripts fournis utilisés, explications README, volumes et capture 25 ; le contrôle renforcé des deux rejeux reste à exécuter |
| C19.2 | Tâches purge → qualité → reconstruction, rôle des outils | [x] TRANSFORMER, captures 13/14/17/19/22 |
| C19.3 | Tags, politiques et descriptions survivent aux tâches | [x] 18 contrôles après tâches, capture 15 ; après rejeu, capture 26 |
| C19.4 | README rejouable ; aucun secret ni donnée personnelle dans Git | [x] Ordre complet, exclusions contrôlées et deux rejeux avec contenus RAW inchangés, capture 28 |
| C20.1 | Chaque table décrite avec source/rythme, colonnes DIM_DRIVER/RAW.DRIVERS décrites | [x] Cinq fiches, 47 colonnes commentées ; zéro commentaire absent dans les contrôles après tâches |
| C20.2 | Toutes les colonnes personnelles taguées ; sensibilité/durée par table | [ ] Extension D01 préparée, 39 colonnes visées ; test 12 et non-régression 10 à exécuter. Extension explicite de la taxonomie initiale |
| C20.3 | Vue catalogue descriptions/tags lisible par métier | [x] V_CATALOGUE, 25 lignes accessibles à ANALYSTE, capture 26 |
| C20.4 | Qualité documentée et lignage présenté | [x] Trois règles, seuils/gravités dans README ; lignage capture 04 |
| C21.1 | Matrice de tous les rôles, administrateur et gouvernance inclus | [x] Capture 27 : 69 contrôles, huit rôles, 22 refus attendus et matrice des deux tables métier, zéro échec ; à recontrôler après extension des tags |
| C21.2 | Extension du périmètre par mapping sans changer la politique | [x] Capture 24, trois étapes conformes et état restauré |
| C21.3 | Purge cinq ans toutes copies, Time Travel un jour | [x] Captures 11/12 ; essai réel après 24 h non réalisé, paramètre prouvé |
| C21.4 | Trois règles dont service_rattache ; mesures et blocage | [x] Captures 16/20/21/22/23, seuil normal rétabli |
| C21.5 | Audit des lectures et registre avec preuves | [x] Capture 07 et registre renseigné ; complément de comptes utilisateurs consultable en privé |

## Livrables et captures

- [x] Dépôt nommé hudson-cab-gouvernance, URL explicite dans README ; état public distant à contrôler après publication des derniers commits.
- [x] README : protection, installation, choix, limites et liens vers les documents.
- [x] snowflake/gouvernance/ : rôles, droits, tags, masques, filtre, mapping, audit et tests.
- [x] snowflake/rh/ : sources SQL, purge, conservation, catalogue, contrôles et tâches.
- [x] VEILLE, REGISTRE, ACCES remplis ; trames vierges retirées du rendu.
- [x] Sept catégories de captures obligatoires ; index dans SUIVI.
- [x] Questions du guide et de conception répondues dans QUESTIONS.md ; soutenance structurée dans SOUTENANCE.md.
- [x] Recettes finales 10 et 11 : captures 27/28, 69 et six contrôles OK.
- [x] Suspension finale de la racine consignée, sans capture dédiée.
- [ ] Migration D01 : couverture 39 colonnes et non-régression des 69 contrôles à prouver.
- [ ] Derniers commits et état public de GitHub à constater après publication.

## Réserves assumées

La classification complète n’est pas un bonus : la décision D01 ajoute deux catégories explicites pour couvrir les vingt attributs absents de la taxonomie initiale. Le contrat de référence reste inchangé ; l’extension est tracée comme un choix de conception, sans validation externe inventée. La preuve de migration reste attendue. Les cinq ans, l’absence d’archive distincte, les copies externes et les pouvoirs administratifs sont expliqués, pas présentés comme une conformité juridique générale.

Les tests 10/11 sont désormais prouvés par les captures 27/28 ; seuls les résultats post-migration 12/10 restent attendus. Les tests en attente sont identifiés par leur résultat manquant. Les scripts et le présent contrôle ne doivent pas être présentés comme la preuve de leur exécution.

## Résultat des deux passes locales

Première passe : confrontation des 17 critères hors bonus, questions du brief/guide, carte des privilèges et fiche de registre. Les comptes rendus chronologiques et trames vierges ont été remplacés par les résultats actuels ; les données non fournies par le scénario sont identifiées explicitement, sans inventer de contact ni de validation juridique.

Seconde passe : aucun lien local cassé dans les livrables, aucune mention d’accompagnement ni champ générique dans les textes courants, exclusions Git vérifiées, aucun CSV du personnel ni fichier de secret suivi dans l’historique. Aucune valeur des coordonnées, licences ou noms complets du fichier RH détectée dans les textes à publier. Les images de preuve présentent des agrégats ou métadonnées. Les blocs de purge/qualité des tâches sont identiques à leurs sources ; le test de rejeu contient deux copies exactes du nouveau bloc de chargement. Les variables de session des recettes sont déclarées ; 69 assertions couvrent huit rôles et 22 refus. Ces contrôles locaux ne valent pas compilation ou exécution dans Snowflake.
