# Spécification — Compétition par équipes au cumul des places

## 1. Statut

**Brouillon à clarifier.**

Cette spécification formalise la demande exprimée le 13 novembre 2026. Elle
décrit un nouveau mode de compétition et n'est pas encore validée ni
implémentée.

## 2. Objectif

Créer un mode de compétition dans lequel :

- les participants sont répartis en équipes ;
- les équipes peuvent être composées manuellement ou aléatoirement ;
- à l'arrivée de chaque boucle, le coach saisit l'ordre des participants ;
- le premier participant marque 1 point ;
- le deuxième marque 2 points ;
- chaque participant marque autant de points que sa place ;
- le dernier marque donc le nombre de concurrents classés : avec 80 concurrents,
  il marque 80 points ;
- les points individuels des membres sont additionnés pour obtenir le score de
  leur équipe ;
- l'équipe gagnante est celle qui possède le **plus petit total de points**.

Ce mode utilise un barème inverse distinct du barème individuel actuel de
l'application.

## 3. Vocabulaire

- **Compétition par équipes** : compétition utilisant les règles définies dans
  ce document.
- **Équipe** : groupe de participants figé pour la compétition.
- **Boucle** : passage donnant lieu à un ordre d'arrivée complet ou partiel et à
  une attribution de points.
- **Place** : position d'un participant à l'arrivée d'une boucle.
- **Points de place** : nombre égal à la place du participant.
- **Score de boucle d'une équipe** : somme des points retenus pour ses membres
  sur une boucle.
- **Score général d'une équipe** : somme de ses scores sur toutes les boucles
  validées.
- **Classement provisoire** : classement recalculé tant que les résultats ne
  sont pas publiés.
- **Classement publié** : classement visible par les athlètes.

## 4. Périmètre

### Inclus

- choix du nouveau mode lors de la création d'une compétition ;
- création manuelle des équipes ;
- génération aléatoire des équipes ;
- déplacement d'un participant entre les équipes avant le départ ;
- affichage des participants sans équipe ;
- saisie rapide de l'ordre d'arrivée à chaque boucle ;
- attribution automatique des points selon la place ;
- calcul du score par équipe et du classement général ;
- correction de l'ordre d'arrivée avec recalcul ;
- validation et publication des résultats ;
- consultation du classement individuel par boucle et du classement par équipes ;
- droits coach et lecture athlète sur Android et sur le web.

### Exclus de cette première version

- changement d'équipe après le démarrage ;
- équipes différentes selon les boucles ;
- handicaps ou coefficients appliqués au score d'équipe ;
- bonus ou pénalités dont la valeur n'est pas encore définie ;
- classement combinant ce mode avec le barème individuel actuel ;
- génération aléatoire fondée sur le niveau sportif, l'âge ou le sexe tant
  qu'une règle d'équilibrage n'est pas confirmée.

## 5. Existant et écarts

L'application gère actuellement des participants, des groupes d'athlètes, des
manches, un ordre d'arrivée et des points individuels.

Observations vérifiées :

- `CalculPoints` utilise actuellement un autre barème ;
- les résultats stockent déjà une position et des points ;
- le classement global actuel trie les totaux individuels du plus grand au plus
  petit ;
- les groupes d'athlètes existants servent à sélectionner rapidement des
  participants, mais ne représentent pas des équipes de compétition avec un
  score ;
- les corrections de résultats recalculent actuellement un barème différent.

Ce nouveau mode exige donc :

- un type de compétition explicite ;
- des équipes rattachées à une compétition ;
- une composition figée et historisée ;
- une stratégie de points dédiée où le minimum gagne ;
- un classement par équipe séparé du classement individuel existant ;
- des opérations serveur transactionnelles adaptées aux corrections.

## 6. Parcours coach

### 6.1 Création de la compétition

1. Le coach crée une compétition.
2. Il choisit le mode **Équipes — cumul des places**.
3. Il définit les épreuves, manches ou boucles selon le modèle retenu.
4. Il ouvre les inscriptions ou ajoute les participants autorisés.

### 6.2 Composition des équipes

Le coach choisit l'une des deux méthodes :

#### Composition manuelle

1. Il crée les équipes et leur donne un nom.
2. Il affecte chaque participant à une équipe.
3. Il peut déplacer un participant d'une équipe à une autre.
4. L'application affiche en permanence :
   - le nombre de membres par équipe ;
   - les participants sans équipe ;
   - les éventuels doublons ou incohérences ;
   - la différence d'effectif entre équipes.

#### Composition aléatoire

1. Le coach choisit le nombre d'équipes ou, selon la décision à confirmer, la
   taille souhaitée des équipes.
2. Il lance la génération.
3. L'application répartit les participants de manière aléatoire avec des
   effectifs aussi équilibrés que possible.
4. Un aperçu est présenté avant confirmation.
5. Le coach peut relancer le tirage ou effectuer des ajustements manuels.
6. La répartition n'est définitive qu'après confirmation.

### 6.3 Saisie d'une boucle

1. Le coach ouvre la boucle en cours.
2. L'écran présente tous les participants attendus, regroupables ou filtrables
   par équipe, avec leur dossard et leur pseudo.
3. À chaque arrivée, le coach appuie sur le participant correspondant.
4. L'application lui attribue immédiatement la prochaine place disponible.
5. Le score provisoire des équipes est recalculé en direct.
6. Le coach traite les participants non arrivés selon le statut confirmé :
   abandon, disqualification, hors délai ou absent.
7. Il vérifie puis valide la boucle.

### 6.4 Correction et publication

1. Le coach peut changer la place d'un participant.
2. Les autres places sont automatiquement décalées ou échangées selon le choix
   d'interface existant.
3. Tous les points individuels et scores d'équipe affectés sont recalculés dans
   la même transaction.
4. Une correction d'un résultat publié dépublie ou invalide le classement selon
   la règle déjà retenue pour les résultats.
5. Le coach valide puis publie le classement.

## 7. Exigences fonctionnelles

- **EF-01 — Choix du mode**  
  Le formulaire de compétition permet de choisir le mode classique ou le mode
  **Équipes — cumul des places**. Le mode choisi est visible dans le détail de
  la compétition.

- **EF-02 — Équipes propres à la compétition**  
  Le coach peut créer, renommer et supprimer une équipe tant que la compétition
  n'a pas démarré.

- **EF-03 — Affectation unique**  
  L'interface empêche qu'un participant appartienne à plusieurs équipes dans
  une même compétition.

- **EF-04 — Composition manuelle**  
  Le coach peut affecter et déplacer les participants manuellement, avec un
  retour immédiat sur les effectifs.

- **EF-05 — Composition aléatoire**  
  Le coach peut générer une répartition aléatoire dont les tailles d'équipes
  diffèrent au maximum d'une personne lorsque l'effectif n'est pas divisible.

- **EF-06 — Aperçu avant confirmation**  
  Une génération aléatoire reste un brouillon jusqu'à sa confirmation. Le coach
  peut l'annuler ou la relancer sans modifier la composition enregistrée.

- **EF-07 — Verrouillage**  
  Au démarrage de la première boucle, les équipes et leurs compositions sont
  figées.

- **EF-08 — Saisie directe des arrivées**  
  Le coach peut attribuer la prochaine place en appuyant directement sur la
  carte d'un participant non encore classé.

- **EF-09 — Retour immédiat**  
  Après une arrivée, l'interface affiche la place, les points du participant et
  le nouveau score provisoire de son équipe.

- **EF-10 — Classement de boucle**  
  L'application affiche pour chaque boucle l'ordre complet des arrivées, les
  points individuels et le score de chaque équipe.

- **EF-11 — Classement général**  
  L'application additionne les scores des boucles validées et classe les équipes
  du plus petit au plus grand total.

- **EF-12 — Correction cohérente**  
  Une correction de place recalcule sans doublon toutes les places, tous les
  points individuels et tous les scores d'équipe concernés.

- **EF-13 — États sportifs**  
  Le coach peut déclarer un abandon, une disqualification, un hors délai ou une
  absence. Leur valeur en points reste soumise aux décisions de la section 14.

- **EF-14 — Validation**  
  Une boucle ne peut être validée que si chaque participant attendu possède une
  place ou un statut final autorisé.

- **EF-15 — Publication**  
  Seuls les classements validés peuvent être publiés. Les athlètes ne voient
  comme officiels que les résultats publiés.

- **EF-16 — Consultation athlète**  
  Un athlète peut consulter son équipe, ses coéquipiers, ses places, ses points
  et le classement publié des équipes.

- **EF-17 — Explication du barème**  
  Les écrans de classement indiquent clairement : « 1 point pour la 1re place,
  2 pour la 2e, etc. L'équipe au plus petit total gagne. »

- **EF-18 — Prévention des doubles saisies**  
  Un double appui ou deux appareils ne peuvent pas attribuer deux places au même
  participant ni la même place à deux participants.

- **EF-19 — Reprise et erreurs**  
  En cas de perte réseau, la saisie affiche son état, permet une nouvelle
  tentative et recharge la position officielle avant toute nouvelle arrivée.

- **EF-20 — Traçabilité**  
  Toute correction conserve au minimum l'auteur, la date, l'ancienne place, la
  nouvelle place et le motif.

## 8. Règles métier

- **RM-01 — Points individuels**  
  Pour un participant classé à la place `p` :

  ```text
  points_individuels = p
  ```

- **RM-02 — Dernière place**  
  Si `N` participants sont classés, le dernier classé obtient `N` points.
  Avec 80 participants classés, les points vont de 1 à 80.

- **RM-03 — Score d'équipe par boucle**  
  Sous réserve de la règle d'effectif à confirmer :

  ```text
  score_equipe_boucle = somme(points des membres retenus)
  ```

- **RM-04 — Score général**  

  ```text
  score_general_equipe = somme(scores_equipe_boucle validés)
  ```

- **RM-05 — Sens du classement**  
  Les équipes sont triées par score croissant. Le plus petit score occupe la
  première place.

- **RM-06 — Composition unique**  
  Un participant ne peut appartenir qu'à une seule équipe dans une compétition.

- **RM-07 — Équipes figées**  
  La composition ne peut plus être modifiée après le démarrage. Une correction
  exceptionnelle nécessiterait une opération d'administration tracée et un
  recalcul complet, hors du parcours normal.

- **RM-08 — Tirage équilibré**  
  La génération aléatoire distribue tous les participants éligibles une seule
  fois et minimise l'écart d'effectif entre équipes.

- **RM-09 — Tirage non prédictible pour l'utilisateur**  
  Deux générations peuvent produire des répartitions différentes. Le résultat
  retenu est persisté ; le classement ne dépend jamais d'un nouveau tirage au
  rechargement.

- **RM-10 — Places continues**  
  En l'absence d'ex aequo, les places des classés sont les entiers continus de 1
  à `N`, sans trou ni doublon.

- **RM-11 — Recalcul transactionnel**  
  Une insertion, suppression ou correction d'arrivée recalcule les positions,
  points et scores dans une seule transaction serveur.

- **RM-12 — Publication et correction**  
  Une correction affectant un classement publié le rend à nouveau provisoire et
  impose une nouvelle validation avant republication.

- **RM-13 — Autorisations**  
  Seul le coach responsable peut gérer les équipes, saisir les arrivées,
  corriger, valider et publier. Ces règles sont appliquées côté serveur et par
  RLS.

- **RM-14 — Lecture athlète**  
  Les athlètes peuvent lire les compositions autorisées et les résultats
  publiés, mais ne peuvent pas modifier une équipe ou un résultat.

- **RM-15 — Suppression**  
  Une équipe sans compétition démarrée peut être supprimée après confirmation.
  Une équipe ayant un historique sportif ne doit pas être supprimée en cascade ;
  elle est conservée ou archivée.

## 9. Exemple de calcul confirmé

### Une boucle avec 80 participants

- 1er : 1 point ;
- 2e : 2 points ;
- 3e : 3 points ;
- … ;
- 79e : 79 points ;
- 80e : 80 points.

### Exemple simplifié avec 12 participants et 3 équipes

| Place | Participant | Équipe | Points |
|---:|---|---|---:|
| 1 | A1 | Orange | 1 |
| 2 | B1 | Bleue | 2 |
| 3 | C1 | Blanche | 3 |
| 4 | A2 | Orange | 4 |
| 5 | C2 | Blanche | 5 |
| 6 | B2 | Bleue | 6 |
| 7 | B3 | Bleue | 7 |
| 8 | A3 | Orange | 8 |
| 9 | C3 | Blanche | 9 |
| 10 | A4 | Orange | 10 |
| 11 | B4 | Bleue | 11 |
| 12 | C4 | Blanche | 12 |

Scores de la boucle :

- Orange : `1 + 4 + 8 + 10 = 23` points ;
- Bleue : `2 + 6 + 7 + 11 = 26` points ;
- Blanche : `3 + 5 + 9 + 12 = 29` points.

Classement :

1. Orange — 23 points ;
2. Bleue — 26 points ;
3. Blanche — 29 points.

Orange gagne, car son total est le plus faible.

## 10. Données et intégrations

Modèle fonctionnel proposé, sans imposer encore les noms SQL définitifs.

### Type de compétition

Ajouter un type ou mode :

- classique ;
- équipes au cumul des places.

### Équipe de compétition

- identifiant ;
- compétition ;
- nom ;
- couleur ou repère visuel facultatif ;
- ordre d'affichage ;
- statut actif ou archivé ;
- dates de création et modification.

### Membre d'équipe

- équipe ;
- participant ;
- date d'affectation ;
- mode d'affectation : manuel ou aléatoire ;
- position éventuelle dans l'équipe.

Contraintes attendues :

- unicité du nom d'équipe dans une compétition, sans distinction de casse ;
- unicité du participant dans une compétition ;
- interdiction d'affecter un participant non inscrit à la compétition.

### Score d'équipe

Le score peut être calculé à la demande depuis les résultats, ou matérialisé avec
une révision contrôlée. Dans les deux cas, il doit contenir ou permettre
d'obtenir :

- équipe ;
- boucle/manche ;
- points de la boucle ;
- nombre de membres comptabilisés ;
- révision des résultats source ;
- état provisoire, validé ou publié.

### Migration

Une migration Supabase sera nécessaire pour :

- ajouter le mode de compétition ;
- créer les équipes et leurs membres ;
- ajouter les contraintes d'intégrité ;
- ajouter les opérations transactionnelles ;
- appliquer les politiques RLS ;
- adapter les fonctions de validation et publication ;
- préserver intégralement les compétitions classiques existantes.

Un fichier d'instructions devra accompagner la migration avant son exécution.

## 11. Critères d'acceptation

- **CA-01 — EF-01**  
  Étant donné une nouvelle compétition, quand le coach choisit le mode par
  équipes, alors le détail affiche ce mode et le barème inverse.

- **CA-02 — EF-05, RM-08**  
  Étant donné 80 participants et 6 équipes, quand le coach génère les équipes,
  alors chaque participant apparaît exactement une fois et les effectifs sont
  de 13 ou 14 membres.

- **CA-03 — EF-06**  
  Quand le coach annule l'aperçu d'un tirage, alors la composition enregistrée
  avant le tirage reste inchangée.

- **CA-04 — EF-03, RM-06**  
  Quand un participant déjà affecté est ajouté à une autre équipe, alors il est
  déplacé explicitement ou l'opération est refusée ; il n'existe jamais dans les
  deux équipes.

- **CA-05 — EF-08, RM-01**  
  Quand le coach sélectionne le premier participant arrivé, alors celui-ci
  reçoit la place 1 et 1 point.

- **CA-06 — RM-02**  
  Avec 80 participants tous classés, le dernier reçoit la place 80 et 80 points.

- **CA-07 — EF-09, RM-03**  
  Quand une nouvelle arrivée est enregistrée, alors le score provisoire de son
  équipe est recalculé et affiché sans recharger l'écran.

- **CA-08 — EF-11, RM-05**  
  Avec des scores de 23, 26 et 29 points, alors l'équipe à 23 points est classée
  première.

- **CA-09 — EF-12, RM-10, RM-11**  
  Quand un participant passe de la place 8 à la place 3, alors les participants
  précédemment classés de 3 à 7 sont décalés, toutes les places restent uniques
  et tous les scores concernés sont recalculés dans la même transaction.

- **CA-10 — EF-14**  
  Quand un participant attendu n'a ni place ni statut final, alors la validation
  de la boucle est refusée avec un message indiquant le participant concerné.

- **CA-11 — EF-18**  
  Quand deux appareils tentent d'attribuer simultanément la même prochaine
  place, alors une seule opération réussit et l'autre recharge le classement.

- **CA-12 — EF-15, RM-12**  
  Quand un résultat publié est corrigé, alors le classement repasse en état
  provisoire et n'est publié de nouveau qu'après validation.

- **CA-13 — EF-16, RM-14**  
  Un athlète voit son équipe et les classements publiés, mais une tentative de
  modification directe est refusée par le serveur.

- **CA-14 — EF-07, RM-07**  
  Après le démarrage de la première boucle, les actions ordinaires de
  modification des équipes sont indisponibles et refusées côté serveur.

- **CA-15 — Compatibilité**  
  Une compétition classique continue d'utiliser son barème et son classement
  actuels sans afficher les écrans d'équipes.

## 12. Scénarios de recette

1. Créer manuellement 4 équipes et répartir 80 participants.
2. Générer aléatoirement 6 équipes avec 80 participants.
3. Relancer un tirage puis l'annuler.
4. Confirmer un tirage puis ajuster manuellement deux participants.
5. Refuser le démarrage si un participant inscrit reste sans équipe, si cette
   règle est confirmée.
6. Saisir successivement 80 arrivées sur une boucle.
7. Corriger plusieurs places et vérifier tous les scores.
8. Gérer un abandon, un hors délai et une disqualification.
9. Valider deux boucles et vérifier le cumul général.
10. Corriger une boucle déjà publiée.
11. Tester une égalité entre deux équipes.
12. Tester deux coachs/appareils saisissant simultanément une arrivée.
13. Vérifier les droits d'un autre coach et d'un athlète.
14. Vérifier Android et web avec chargement, erreur réseau et reprise.

## 13. Propositions techniques

Ces propositions ne constituent pas encore des décisions d'implémentation :

- introduire une stratégie de classement selon le mode de compétition, plutôt
  que modifier `CalculPoints` pour tous les modes ;
- créer des entités de domaine dédiées `EquipeCompetition`,
  `MembreEquipe` et `ClassementEquipe` ;
- conserver les groupes d'athlètes existants séparés des équipes officielles ;
- centraliser le calcul pur du score dans un service de domaine testable ;
- effectuer la saisie d'arrivée, la correction et le recalcul via des fonctions
  Supabase transactionnelles et idempotentes ;
- utiliser une contrainte différable pour les réordonnancements de places, sans
  utiliser `ON CONFLICT` sur cette contrainte ;
- afficher le score en direct avec une vue par boucle et une vue générale ;
- présenter les équipes avec un nom, une couleur et un symbole, sans dépendre
  uniquement de la couleur pour l'accessibilité.

## 14. Questions et décisions à confirmer

1. **Nombre ou taille des équipes** : le coach choisit-il le nombre d'équipes,
   le nombre de personnes par équipe, ou les deux avec validation ?
2. **Participants sans équipe** : peut-on démarrer si certains inscrits ne sont
   affectés à aucune équipe ?
3. **Équipes inégales** : additionner tous les membres avantage ou désavantage
   les équipes selon leur taille. Faut-il imposer des tailles égales, ne retenir
   que les `K` meilleurs membres de chaque équipe, ou calculer une moyenne ?
4. **Abandon, hors délai, absence et disqualification** : combien de points
   attribuer ? Une proposition possible est `N + 1`, mais elle doit être
   validée avant toute implémentation.
5. **Ex aequo individuels** : la saisie manuelle impose-t-elle toujours un ordre
   strict, ou deux participants peuvent-ils partager une place ?
6. **Égalité entre équipes** : quel départage utiliser : meilleure dernière
   boucle, plus grand nombre de premières places, meilleur dernier membre,
   confrontation directe, ou équipes ex aequo ?
7. **Boucle et manche** : une boucle correspond-elle exactement à une manche
   existante, ou plusieurs boucles appartiennent-elles à une seule manche ?
8. **Score général** : toutes les boucles comptent-elles, ou peut-on retirer la
   moins bonne boucle de chaque équipe ?
9. **Tirage aléatoire** : doit-il être purement aléatoire ou équilibré par niveau
   sportif/catégorie ?
10. **Visibilité des équipes** : les compositions sont-elles visibles dès leur
    confirmation ou seulement au démarrage/publication ?
11. **Modification exceptionnelle** : faut-il permettre au coach de remplacer un
    absent après le démarrage, et avec quelles conséquences sur l'historique ?
12. **Nom et identité** : le coach choisit-il librement noms et couleurs, ou
    l'application propose-t-elle automatiquement « Équipe 1 », « Équipe 2 »,
    etc. ?
