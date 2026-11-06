# Questions de conception et réponses

## Pourquoi le RGPD et qui est responsable ?

Hudson Cab Europe décide des finalités et moyens depuis son établissement parisien : article 3 §1 pour le champ territorial et article 4 §7 pour le responsable. La résidence new-yorkaise des chauffeurs n’exclut pas cette application. L’hébergement à Paris n’en est pas le fondement. Snowflake est le prestataire de traitement pour le compte du responsable ; les dispositions de l’article 28 doivent être vérifiées. Le brief ne permet pas de qualifier automatiquement Hudson Cab Partners de sous-traitant.

Sources et fiches : [VEILLE.md](VEILLE.md). Les données professionnelles et les agrégats par chauffeur restent personnels ; D0042 est un identifiant indirect, pas une anonymisation.

## Comment être prévenu d’une nouvelle recommandation ?

L’abonnement CNIL en place avertit par courriel. Une revue manuelle hebdomadaire couvre CNIL, CEPD/EDPB et EUR-Lex ; le journal précise date, impact et action. Une recommandation est examinée avec le conseil juridique avant modification des règles, puis traduite en scripts et tests. Le rythme de revue est défini, sans prétendre disposer déjà d’un historique hebdomadaire.

## Une licence TLC publique doit-elle être visible de tous ?

Non. Public ne signifie pas nécessaire pour tous les usages. Une licence identifie le chauffeur ; sa lecture est limitée au besoin prévu par le contrat. Paie et pipeline la lisent en clair ; responsables et analyste la lisent masquée. Le tag SENSIBILITE d’une table décrit sa classification interne, pas le caractère public d’une source externe.

## Pourquoi masquer plutôt que supprimer ?

La paie et les transformations ont besoin de certaines valeurs que les autres lecteurs n’ont pas à connaître. Le masque adapte la lecture au rôle sans créer une copie personnelle supplémentaire. Si aucun usage légitime ne justifie une colonne, la minimisation conduirait à la supprimer ; le masquage ne remplace pas cette analyse. Le tag décrit la nature ; une politique et des droits produisent la protection.

## Un chauffeur parti depuis trois ans doit-il avoir les mêmes accès qu’un actif ?

Le contrat permet sa conservation jusqu’à cinq ans et ne distingue pas archive/base active : c’est le comportement appliqué et testé. Cela ne suffit pas à justifier les mêmes usages courants. La proposition est de définir une archive intermédiaire, les seules catégories nécessaires, des droits restreints et leurs durées. Cette évolution doit être décidée par le responsable du traitement ; elle n’est pas appliquée silencieusement.

## Pourquoi une table de correspondance ? Et Staten Island ?

La politique cherche le rôle actif et le dépôt dans ACCES_DEPOT. Ajouter une habilitation rôle/dépôt étend le périmètre sans changer la politique. Pour un nouveau garage réel, il faut aussi faire évoluer le référentiel DIM_DEPOT, le système source et la règle depot_connu si utilisée. Les expressions du contrat limitées aux trois dépôts devront être revues : une habilitation technique ne modifie pas une règle métier. La preuve Queens+Bronx illustre l’extension du périmètre (capture 24).

## Que voit TRANSFORMER, et pourquoi ?

Le chargement, la qualité, la purge et la reconstruction nécessitent les données en clair. Appliquer un masque au pipeline pourrait inscrire [MASQUE] dans les tables. TRANSFORMER dispose de ces lectures et possède ses objets ; il ne reçoit pas les pouvoirs généraux d’ACCOUNTADMIN. Sa compromission reste critique : suspendre les tâches, retirer les accès compromis, renouveler l’authentification et examiner les journaux. Voir le registre et la carte des droits.

## Et si les RH renvoient le mois prochain un fichier complet depuis 2005 ?

Une purge ne rend pas le passé impossible à recharger. Chaque nouvelle livraison doit être chargée avec une stratégie explicite de remplacement ou rapprochement : les COPY fournis seuls ne constituent pas un rapprochement métier d’un nouveau snapshot. Un fichier différent peut ajouter des doublons ou des données obsolètes ; le suivi des fichiers de COPY n’est pas une clé métier. Rejouer la purge sur RAW et toutes les copies avant reconstruction et ouverture des usages, puis contrôler la qualité. Pour une exploitation réelle, charger et valider le snapshot en zone d’intégration non exposée avant bascule. Cette gestion complète des nouvelles livraisons n’est pas implémentée par le kit.

## Pourquoi purger RAW et aussi les services ?

Si RAW conserve une personne expirée, le prochain pipeline peut la réintroduire dans MARTS. Les services contiennent driver_id et sont donc personnels aussi : la purge efface les copies mensuelles, la dimension, les services RAW puis la source DRIVERS dans une transaction. Dans ce jeu, aucun service ne concerne les 46 personnes expirées ; leur compteur reste donc 25 951. Les 25 services orphelins existants sont un problème qualité distinct.

## Au bout de combien de jours une donnée purgée disparaît-elle réellement ?

L’utilisateur peut consulter Time Travel pendant un jour configuré. Les tables permanentes ont ensuite sept jours de Fail-safe, sans consultation métier ordinaire. Succession nominale : huit jours après la suppression, sans promesse d’effacement physique à heure fixe ; requêtes longues, clones, sauvegardes ou copies externes peuvent modifier le bilan. La purge quotidienne ajoute jusqu’à environ 24 heures entre l’expiration métier et le passage de la tâche. Le projet prouve le paramètre et l’état historique, pas une disparition physique observée après huit jours. Références dans VEILLE.md et REGISTRE.md.

## Peut-on se fier aux données malgré les alertes ?

Le contrôle explique une limite de confiance, il ne corrige pas la valeur. licence_unique=4 et email_valide=7 produisent des avertissements ; service_rattache=25 respecte le seuil 50. OK signifie seuil respecté, pas données parfaites. Au seuil temporaire 0, la qualité échoue, conserve les mesures et empêche la reconstruction ; le seuil final revient à 50. Les cinq autres contrôles proposés au contrat sont hors de l’implémentation minimale de trois règles, pas des bonus manquants.

## Pourquoi ACCOUNTADMIN apparaît-il dans l’audit avec zéro ligne aux tests ?

ACCESS_HISTORY enregistre les objets et colonnes référencés ; QUERY_HISTORY apporte le rôle par query_id. Cela ne prouve ni ligne retournée ni valeur visible en clair. Les tests de lecture apportent cette preuve. L’audit agrégé public masque les comptes utilisateurs ; le complément nominatif se consulte uniquement dans Snowflake. ACCESS_HISTORY peut avoir jusqu’à trois heures de retard.

## Les règles survivent-elles au pipeline et à leur propre rejeu ?

Les INSERT OVERWRITE modifient les contenus sans recréer les tables, ce qui conserve tags, descriptions et politiques. Les scripts créent conditionnellement puis modifient les politiques en place. Les captures 15 et 26 donnent 18 contrôles OK après pipeline puis rejeu des règles. La création/modification des tâches est distincte de leur activation ; une modification du graphe impose d’abord de suspendre la racine.

## Pourquoi toutes les colonnes personnelles ne sont-elles pas taguées ?

Le contrat impose six catégories d’identité/coordonnées/identifiants mais le brief exige un tag pour toutes les données personnelles, dont affectation et mesures d’activité. Ces attributs ne correspondent pas aux six valeurs. L’inventaire reste complet, les descriptions les identifient, la vue signale ECART_TAG_CONTRAT et les politiques directes les protègent. La couverture complète C20 reste non satisfaite : il faut une décision sur la taxonomie pour lever cet écart. Aucun résultat de protection ne transforme cet écart en conformité de catalogue.
