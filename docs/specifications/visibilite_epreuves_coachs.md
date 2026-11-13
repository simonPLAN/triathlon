# Spécification — Visibilité de toutes les épreuves entre coachs

## 1. Statut

**Brouillon à clarifier.**

Cette spécification formalise la demande exprimée le 13 novembre 2026. Elle
n'est pas encore validée ni implémentée.

## 2. Objectif

Tout utilisateur possédant réellement le rôle **coach** doit pouvoir consulter
les épreuves créées par tous les coachs de l'application.

Cette ouverture concerne la **lecture des épreuves**. Elle ne transfère pas la
propriété et n'accorde aucun droit de modification sur les compétitions,
épreuves, manches, inscriptions ou résultats d'un autre coach.

Le coach responsable conserve seul les actions de création, configuration,
réorganisation, suppression, démarrage, saisie, validation et publication sur
ses propres données.

## 3. Périmètre

### Inclus

- accès à une liste globale des épreuves pour tous les coachs ;
- accès aux informations publiques ou organisationnelles de chaque épreuve ;
- identification de la compétition parente et du caractère « m'appartient » ;
- consultation en lecture seule des épreuves d'un autre coach ;
- recherche, filtres, tri, actualisation et pagination éventuelle ;
- prise en compte de tous les statuts de compétition, sous réserve de la
  décision sur les brouillons ;
- règles RLS distinctes pour la lecture et l'écriture ;
- affichage Android et web.

### Exclus

- modification d'une épreuve appartenant à un autre coach ;
- accès automatique aux inscriptions d'un autre coach ;
- accès aux profils ou coordonnées des participants ;
- accès aux profils invités d'un autre coach ;
- accès aux résultats provisoires ou non publiés ;
- saisie des arrivées, correction, validation ou publication pour un autre
  coach ;
- coorganisation et délégation de droits ;
- copie ou import d'une épreuve d'un autre coach ;
- accès public sans authentification.

### Rôles

- **Coach responsable** : lecture et actions existantes sur ses propres
  épreuves.
- **Autre coach actif** : lecture seule des épreuves autorisées.
- **Athlète** : droits inchangés ; cette fonctionnalité ne lui ouvre aucune
  donnée supplémentaire.
- **Visiteur non connecté** : aucun accès ajouté.
- **Compte archivé, invité ou rôle déclaré uniquement dans les métadonnées** :
  aucun droit coach.

## 4. Existant et écarts

Observations vérifiées :

- `EpreuveRepositorySupabase` charge actuellement les épreuves à partir de
  l'identifiant d'une compétition ;
- `EpreuvesPage` suppose un contexte de compétition et affiche les actions de
  configuration selon le statut brouillon ;
- les écritures passent par des RPC contrôlant que la compétition appartient au
  coach connecté ;
- les politiques de production conditionnent actuellement la lecture des
  épreuves à `programme_competition_visible(competition_id)` ;
- le helper `securite_coach_competition` vérifie la propriété de la
  compétition, pas seulement le rôle coach.

La demande nécessite :

- une autorisation de lecture globale propre aux coachs actifs ;
- une source paginée ou filtrable indépendante d'une compétition précise ;
- un écran ou un onglet de consultation globale ;
- un calcul explicite des capacités d'action selon la propriété ;
- le maintien sans changement des contrôles d'écriture actuels.

## 5. Parcours coach

1. Le coach ouvre la section **Épreuves**.
2. Il peut choisir :
   - **Mes épreuves** ;
   - **Toutes les épreuves**.
3. La vue globale affiche les épreuves accessibles avec au minimum :
   - nom de l'épreuve ;
   - discipline ;
   - distance ;
   - compétition parente ;
   - date de la compétition ;
   - statut de la compétition ;
   - nombre de manches ;
   - indicateur **Mon épreuve** ou **Lecture seule**.
4. Il peut rechercher par nom d'épreuve ou de compétition.
5. Il peut filtrer par discipline, statut, période et propriété.
6. Il ouvre une épreuve.
7. Si elle appartient à un autre coach, l'écran indique clairement
   **Consultation uniquement** et ne présente aucune action d'écriture.
8. Si elle lui appartient, il retrouve les actions déjà autorisées par le statut
   et les règles métier.
9. En cas d'erreur de chargement, les données déjà affichées restent
   identifiables comme anciennes et une nouvelle tentative est proposée.

## 6. Exigences fonctionnelles

- **EF-01 — Vue globale**  
  Tout coach actif dispose d'un accès clair à la liste de toutes les épreuves
  autorisées.

- **EF-02 — Vue personnelle conservée**  
  Le coach peut continuer à afficher uniquement les épreuves de ses propres
  compétitions.

- **EF-03 — Contexte obligatoire**  
  Chaque ligne indique la compétition parente afin qu'une épreuve ne soit jamais
  présentée sans contexte.

- **EF-04 — Propriété visible**  
  L'interface distingue sans ambiguïté une épreuve appartenant au coach d'une
  épreuve appartenant à un autre coach.

- **EF-05 — Lecture seule**  
  Pour une épreuve d'un autre coach, les actions créer, modifier, réordonner,
  supprimer, configurer les participants, démarrer, terminer, corriger, valider
  et publier ne sont pas proposées.

- **EF-06 — Refus expliqué**  
  Si une action devient indisponible après actualisation, l'interface explique
  que seul le coach responsable peut la réaliser.

- **EF-07 — Recherche**  
  Le coach peut rechercher une épreuve par son nom ou celui de sa compétition.

- **EF-08 — Filtres**  
  Le coach peut filtrer au minimum par discipline, statut de compétition et
  propriété.

- **EF-09 — Tri stable**  
  Par défaut, les épreuves sont regroupées par compétition, les compétitions
  sont triées par date, puis les épreuves par ordre configuré.

- **EF-10 — Détail consultable**  
  Le coach lecteur peut consulter les données descriptives de l'épreuve et les
  informations de programme explicitement autorisées.

- **EF-11 — Données sensibles exclues**  
  La lecture globale ne retourne ni inscriptions, ni dossards, ni participants,
  ni profils invités, ni résultats non publiés.

- **EF-12 — Résultats publiés inchangés**  
  La visibilité des résultats continue de suivre ses propres règles de
  publication ; voir une épreuve ne donne pas accès aux résultats provisoires.

- **EF-13 — Actualisation**  
  La vue globale peut être actualisée sans changer d'onglet et indique le
  chargement, l'erreur et la possibilité de réessayer.

- **EF-14 — État vide**  
  Si aucun élément ne correspond aux filtres, l'écran indique qu'aucune épreuve
  ne correspond et propose d'effacer les filtres.

- **EF-15 — Pagination ou chargement progressif**  
  La liste ne dépend pas du chargement en une seule fois de toutes les épreuves
  lorsque leur nombre augmente. La taille de page reste une décision technique
  à mesurer.

- **EF-16 — Conservation de l'état**  
  Le choix Mes épreuves/Toutes les épreuves, les filtres et la recherche sont
  conservés pendant la navigation vers un détail puis le retour.

- **EF-17 — Rôle révoqué**  
  Si le rôle coach est retiré ou la session expire, le prochain accès ou
  rafraîchissement refuse la vue globale et renvoie vers le parcours approprié.

- **EF-18 — Compatibilité Android/web**  
  Le même périmètre de données et les mêmes droits sont appliqués sur Android et
  sur le web.

## 7. Règles métier et autorisations

- **RM-01 — Coach valide**  
  Un coach lecteur est un profil authentifié, non invité, non archivé, lié à son
  compte et dont le rôle stocké côté serveur vaut `coach`.

- **RM-02 — Lecture globale**  
  Un coach valide peut lire les champs autorisés des épreuves incluses dans le
  périmètre de visibilité confirmé.

- **RM-03 — Écriture propriétaire**  
  Seul le coach dont l'identifiant correspond à `competitions.coach_id` peut
  modifier les données de cette compétition et de ses épreuves.

- **RM-04 — Aucun héritage d'écriture**  
  Le droit global de lecture ne doit apparaître dans aucune condition
  `INSERT`, `UPDATE` ou `DELETE`.

- **RM-05 — Contrôle serveur**  
  Le rôle, la propriété et le statut sont contrôlés par les RPC et la RLS. Le
  masquage des boutons ne constitue pas une autorisation.

- **RM-06 — Données minimales**  
  La vue globale retourne uniquement les données nécessaires à la consultation
  des épreuves et de leur contexte.

- **RM-07 — Identité du responsable**  
  Par défaut, l'identifiant technique du coach n'est pas affiché. L'affichage de
  son pseudo ou du nom de son organisation reste à confirmer.

- **RM-08 — Brouillons**  
  L'accès aux épreuves de compétitions en brouillon reste une décision ouverte.
  Tant qu'elle n'est pas confirmée, il ne doit pas être présenté comme validé.

- **RM-09 — Compétitions annulées**  
  Les épreuves annulées ou rattachées à une compétition annulée sont signalées
  comme telles et ne sont jamais présentées comme actives.

- **RM-10 — Résultats séparés**  
  Le droit de lire une épreuve n'accorde aucun droit supplémentaire sur
  `resultats`, `inscriptions`, `participants_manche` ou `profils`.

- **RM-11 — Médias**  
  Si les affiches d'épreuve sont implémentées, leur lecture suit la visibilité
  confirmée de l'épreuve, sans élargir le droit de les modifier.

- **RM-12 — Cohérence**  
  Une épreuve n'est retournée que si sa compétition parente existe et fait
  partie du même résultat de lecture autorisé.

- **RM-13 — Révocation immédiate**  
  Le droit n'est pas mémorisé comme une permission permanente dans le client ;
  il est réévalué par le serveur à chaque lecture.

- **RM-14 — Journalisation**  
  La simple lecture n'a pas besoin d'un historique fonctionnel détaillé, sauf
  obligation de sécurité ou d'administration à confirmer.

## 8. Matrice des droits

| Action | Coach responsable | Autre coach | Athlète |
|---|---:|---:|---:|
| Voir les informations autorisées de l'épreuve | Oui | Oui | Selon règles actuelles |
| Voir la compétition parente minimale | Oui | Oui | Selon règles actuelles |
| Voir les inscriptions et dossards | Oui | Non | Données personnelles uniquement |
| Voir les participants d'une manche | Oui | Non | Selon programme personnel |
| Voir les résultats non publiés | Oui | Non | Non |
| Voir les résultats publiés | Oui | Selon règle de publication | Selon règle actuelle |
| Modifier ou supprimer l'épreuve | Selon statut | Non | Non |
| Configurer ou démarrer une manche | Oui | Non | Non |
| Saisir, corriger, valider ou publier | Oui | Non | Non |

## 9. Données et intégrations

### Projection de lecture globale proposée

Une vue ou RPC dédiée peut retourner :

- identifiant de l'épreuve ;
- nom ;
- discipline ;
- distance en mètres ;
- nombre de manches ;
- ordre ;
- durée limite si elle est considérée consultable ;
- identifiant de la compétition ;
- nom, date, lieu et statut de la compétition ;
- booléen `est_proprietaire` calculé côté serveur ;
- éventuelle affiche principale lorsque cette fonctionnalité existe ;
- date de modification pour l'actualisation.

Elle ne retourne pas :

- identifiants ou profils des athlètes ;
- inscriptions et dossards ;
- composition des groupes ;
- résultats non publiés ;
- commentaires internes ;
- données d'authentification.

### Supabase et RLS

Une migration sera nécessaire pour :

- définir un helper de lecture globale réservé aux coachs valides ;
- autoriser le `SELECT` des épreuves concernées ;
- autoriser la lecture minimale des compétitions parentes ;
- conserver strictement les plafonds d'écriture propriétaires ;
- ne pas élargir les policies des tables sensibles ;
- tester les interactions avec les policies permissives et restrictives
  existantes ;
- fournir une RPC ou une vue paginée évitant des requêtes multiples ;
- documenter le retour arrière.

La migration devra être accompagnée d'un fichier d'instructions et testée avec
plusieurs comptes avant tout déploiement.

## 10. Critères d'acceptation

- **CA-01 — EF-01, RM-01, RM-02**  
  Étant donné deux coachs actifs A et B, quand A ouvre Toutes les épreuves,
  alors il voit les épreuves autorisées de A et de B.

- **CA-02 — EF-04**  
  Les épreuves de A affichent « Mon épreuve » et celles de B affichent
  « Lecture seule ».

- **CA-03 — EF-05, RM-03, RM-04**  
  Quand A ouvre une épreuve de B, alors aucune action d'écriture n'est proposée
  et une tentative directe de modification est refusée par le serveur.

- **CA-04 — EF-11, RM-10**  
  Quand A consulte une épreuve de B, alors la réponse ne contient ni inscription,
  ni dossard, ni participant, ni profil invité, ni résultat provisoire.

- **CA-05 — EF-07**  
  Quand A recherche une partie du nom d'une épreuve ou de sa compétition, alors
  seuls les éléments correspondants restent affichés.

- **CA-06 — EF-08**  
  Quand A choisit la discipline natation et le filtre Lecture seule, alors la
  liste n'affiche que les épreuves de natation appartenant à d'autres coachs.

- **CA-07 — EF-09**  
  Dans une même compétition, les épreuves apparaissent selon leur champ
  `ordre`, même si leurs noms sont différents.

- **CA-08 — EF-12**  
  Quand une épreuve de B possède des résultats non publiés, alors A ne peut pas
  les lire par la vue globale ni par une requête directe.

- **CA-09 — EF-13**  
  Quand le chargement échoue après qu'une liste a déjà été affichée, alors la
  liste reste visible avec un avertissement et une action Réessayer.

- **CA-10 — EF-14**  
  Quand aucun résultat ne correspond aux filtres, alors l'écran affiche un état
  vide et une action Effacer les filtres.

- **CA-11 — EF-16**  
  Quand A ouvre un détail puis revient, alors sa vue, sa recherche et ses filtres
  sont conservés.

- **CA-12 — EF-17, RM-13**  
  Quand le rôle coach de A est révoqué, alors une nouvelle lecture globale est
  refusée même si A avait précédemment chargé la liste.

- **CA-13 — RM-01**  
  Un profil invité, archivé ou portant seulement un rôle coach dans des
  métadonnées client ne peut pas lire la vue globale.

- **CA-14 — Compatibilité**  
  Les mêmes comptes obtiennent le même périmètre autorisé sur Android et sur le
  web.

- **CA-15 — Non-régression**  
  Le coach responsable conserve ses actions existantes et les droits athlètes
  ne sont pas élargis.

## 11. Scénarios de recette

1. Créer trois coachs avec plusieurs compétitions et épreuves.
2. Vérifier Mes épreuves puis Toutes les épreuves pour chacun.
3. Tester recherche, discipline, statut, propriété et combinaison de filtres.
4. Ouvrir en lecture seule l'épreuve d'un autre coach.
5. Tenter directement chaque opération d'écriture avec le JWT d'un autre coach.
6. Vérifier que les inscriptions, invités et résultats provisoires restent
   inaccessibles.
7. Vérifier les résultats publiés selon leurs règles existantes.
8. Tester une compétition brouillon selon la décision retenue.
9. Tester les compétitions ouvertes, en cours, terminées et annulées.
10. Tester un profil athlète, invité, archivé et une session absente.
11. Révoquer un rôle coach pendant une session.
12. Simuler une erreur réseau et une reprise.
13. Tester une volumétrie suffisante pour valider la pagination.
14. Vérifier Android, web, petit écran et texte agrandi.
15. Exécuter le Security Advisor et les tests RLS multi-comptes avant production.

## 12. Propositions techniques

Ces éléments sont des pistes, pas des décisions produit :

- ajouter une opération de lecture globale dédiée au port d'épreuves, sans
  modifier la sémantique de `obtenirParCompetition` ;
- retourner une projection dédiée au catalogue coach plutôt qu'une entité
  `Epreuve` dépourvue du contexte de compétition ;
- calculer `est_proprietaire` côté serveur à partir de `auth.uid()` ;
- utiliser une RPC paginée avec recherche et filtres validés côté serveur ;
- conserver les RPC d'écriture existantes et leurs vérifications de propriété ;
- créer une page de catalogue distincte ou un sélecteur Mes épreuves/Toutes les
  épreuves dans l'espace coach ;
- réutiliser les composants d'état vide, erreur et badge de statut existants.

## 13. Questions et décisions à confirmer

1. **Brouillons** : tous les coachs voient-ils aussi les épreuves encore en
   brouillon, ou uniquement celles des compétitions ouvertes, en cours,
   terminées ou annulées ?
2. **Manches** : un autre coach peut-il consulter le programme détaillé des
   manches, ou seulement les informations générales de l'épreuve ?
3. **Résultats publiés** : les coachs peuvent-ils consulter les résultats publiés
   d'une épreuve à laquelle ils ne participent pas ?
4. **Responsable** : faut-il afficher le pseudo du coach responsable, le nom
   d'une organisation, ou seulement « Autre coach » ?
5. **Durée limite** : ce paramètre d'organisation doit-il être visible par tous
   les coachs ?
6. **Affiches** : les affiches prévues dans la spécification dédiée suivent-elles
   cette visibilité globale entre coachs ?
7. **Copie** : faut-il plus tard permettre de dupliquer une épreuve visible dans
   sa propre compétition, sans modifier l'originale ?
8. **Tri initial** : faut-il afficher d'abord les compétitions les plus proches,
   les plus récentes ou celles en cours ?
