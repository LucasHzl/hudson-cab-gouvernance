# Préparer la soutenance — quinze minutes

Les résultats ci-dessous sont ceux observés le 6 novembre 2026 après purge. Refaire une lecture ne remet pas automatiquement les volumes initiaux à 400. Conserver les captures initiales pour présenter l’avant/après.

## Veille — cinq minutes

1. Contexte : Hudson Cab Europe décide des finalités et moyens du traitement depuis Paris. Le RGPD s’applique par l’article 3 §1, même si les chauffeurs travaillent à New York. La localisation du serveur n’est pas le fondement de cette conclusion.
2. Donnée personnelle : ni le caractère professionnel, ni un identifiant tel que D0042 ne rendent une ligne anonyme. Le lien au chauffeur suffit ; les agrégats individuels restent personnels.
3. Écart principal : cinq ans uniformes ne justifient pas la conservation de chaque attribut pour chaque usage. Proposer des durées par finalité et une archive à accès limité ; ne pas affirmer que cinq ans sont automatiquement illégaux ou que les durées françaises s’appliquent aux contrats new-yorkais.
4. Veille : trois sources officielles, revue proposée chaque vendredi, lettre CNIL réellement souscrite. Présenter les fiches de VEILLE.md et la capture 01. Ne pas présenter les autres abonnements comme déjà configurés.

## Gouvernance — dix minutes

| Durée | Démonstration | Pourquoi |
|---|---|---|
| 1 min | Catalogue V_CATALOGUE, description et tags | Savoir ce qu’on protège et d’où cela vient |
| 2 min | Même requête par rôle, tests/03_demo_quatre_roles.sql | Masque = valeur transformée ; filtre = ligne invisible. Après purge : paie/analyste 354, Queens 143, administrateur 0 |
| 1 min | tests/02_test_mapping.sql, tableau des trois étapes | Ajouter Bronx change l’habilitation dans la table, sans modifier la politique ; le script retire ensuite l’ajout |
| 2 min | Graphe et captures 19 à 23 | Purge, puis qualité, puis reconstruction. Montrer l’échec au seuil 0 et les mesures conservées ; seuil final 50 |
| 1 min | Capture 15, 18 contrôles après reconstruction | Les INSERT OVERWRITE remplacent les contenus sans recréer les objets protégés |
| 1 min | Captures 11/12 et règle de purge | 400 → 354, copies expirées supprimées ; Time Travel un jour et Fail-safe distinct |
| 1 min | Audit 06_audit.sql | Qui référence les colonnes, avec quel rôle ; distinguer référence et visibilité en clair |
| 1 min | Lineage de MART_DRIVER_MONTHLY et limites | Services STAGING + dimension ; expliquer l’extension de catégories D01 et la justification juridique des durées |

Le rejeu du test de mapping est réversible. Les tests de blocage changent temporairement le seuil : privilégier leurs preuves conservées si le temps manque ; si relancés, rétablir 50 avec tests/08_retablir_seuil.sql avant de finir. Après la dernière démonstration, suspendre la racine des tâches avec rh/suspendre_taches_rh.sql.

## Questions de compréhension

- Pourquoi un tag ne protège-t-il pas à lui seul ? Il décrit ; une politique ou un droit doit exploiter cette information. DEPOT doit être classé sans masque automatique puisqu’il est la clé du filtre de lignes.
- Pourquoi tester TRANSFORMER ? Un masque appliqué au pipeline pourrait écrire des valeurs masquées dans les tables métier.
- Pourquoi supprimer aussi RAW ? Une reconstruction pourrait sinon réintroduire les personnes purgées de MARTS.
- Pourquoi voir ACCOUNTADMIN dans l’audit n’est-il pas une fuite prouvée ? Le journal décrit une référence à l’objet ; les tests vérifient les lignes et valeurs obtenues.
- Pourquoi 25 anomalies peuvent-elles donner OK ? Le résultat respecte le seuil contractuel 50 ; OK signifie seuil respecté, pas absence d’erreur.
