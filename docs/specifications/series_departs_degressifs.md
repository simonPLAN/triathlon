# Spécification — Séries à départs dégressifs

## 1. Statut

**Brouillon à clarifier.**

Cette spécification formalise la demande exprimée le 13 novembre 2026. Elle ne
vaut pas encore validation métier et n'est pas implémentée.

## 2. Objectif et source

Le coach doit pouvoir configurer une série répétée, par exemple **5 × 500 m** ou
**10 × 1 000 m**, avec un intervalle de départ qui diminue à chaque répétition.

Exemple fourni :

- répétition 1 : départ sur 3 min ;
- répétition 2 : départ sur 2 min 45 s ;
- répétition 3 : départ sur 2 min 30 s ;
- puis poursuite de la dégression.

Dans le vocabulaire de cette spécification, le **temps de départ** est
l'intervalle entre le départ d'une répétition et celui de la répétition suivante.
Il comprend donc le temps d'effort et la récupération restante.

Exemple : avec un départ sur 3 min et un 500 m réalisé en 2 min 20 s, la
récupération disponible est de 40 s.

## 3. Périmètre

### Inclus

- configuration d'une série à répétitions de distance identique ;
- intervalle initial et dégression entre les répétitions ;
- aperçu des horaires relatifs avant le lancement ;
- chronomètre de la répétition et de la récupération ;
- enchaînement automatique selon le planning calculé ;
- saisie et correction des temps de chaque répétition ;
- consultation de la série par le coach et les athlètes concernés ;
- conservation du fonctionnement actuel des manches classiques.

### Exclus de cette première version

- séries avec des distances différentes dans une même série ;
- dégression non linéaire définie temps par temps ;
- programmes complets composés de plusieurs blocs et pauses inter-blocs ;
- recommandation automatique des temps selon le niveau de l'athlète ;
- modification d'une série déjà démarrée ;
- classement ou attribution de points spécifiques à une série d'entraînement,
  tant que la finalité compétition ou entraînement n'est pas confirmée.

### Rôles

- **Coach/arbitre** : configure, lance, suit, corrige et termine la série.
- **Athlète affecté** : consulte le programme, le compte à rebours et ses temps.
- **Athlète non affecté** : ne voit pas les données individuelles de la série.

Plateformes concernées : Android et web.

## 4. Existant et écarts

L'application possède actuellement :

- une durée limite après la première arrivée ;
- une sélection de participants et un ordre de départ par manche ;
- un seul horaire de départ réel par manche ;
- un enchaînement de la manche suivante après la fin de la précédente.

Fichiers observés :

- `lib/domain/entities/manche.dart` ;
- `lib/presentation/widgets/manche/configurer_participants_dialog.dart` ;
- `lib/presentation/pages/manche/detail_manche_page.dart` ;
- `docs/correctif_enchainement_manches.md`.

Le champ actuel `dureeLimiteSecondes` ne représente pas l'intervalle de départ :
il commence après la première arrivée et sert à déclarer les autres athlètes hors
délai. Il ne doit pas être réutilisé pour les départs dégressifs.

Le modèle actuel termine une manche avant d'en démarrer une autre. Une série
cadencée exige au contraire que le prochain départ soit piloté par une échéance
calculée, même si toutes les opérations de résultat de la répétition précédente
ne sont pas encore terminées.

## 5. Parcours coach

1. Le coach choisit le mode **Série à départs dégressifs** lors de la
   configuration d'une épreuve ou d'un ensemble de manches.
2. Il renseigne :
   - nombre de répétitions ;
   - distance de chaque répétition en mètres ;
   - intervalle initial ;
   - diminution appliquée après chaque répétition ;
   - participants ou groupes ;
   - règle à appliquer si un temps dépasse l'intervalle.
3. L'application affiche un aperçu complet des répétitions et des départs
   relatifs.
4. Le coach confirme la configuration.
5. Au lancement, la première répétition part immédiatement après le compte à
   rebours de départ.
6. Pour chaque répétition, l'écran affiche simultanément :
   - le numéro et la distance ;
   - le temps d'effort courant ;
   - le temps avant le prochain départ ;
   - les temps déjà saisis ;
   - la prochaine cadence.
7. À l'échéance prévue, l'application signale et déclenche le départ suivant
   selon la règle confirmée.
8. À la fin, le coach vérifie et corrige les temps avant toute publication
   éventuelle.

## 6. Exigences fonctionnelles

- **EF-01 — Mode explicite**  
  Le coach peut choisir une série dégressive sans modifier le comportement des
  manches classiques.

- **EF-02 — Configuration minimale**  
  Le formulaire permet de saisir le nombre de répétitions, la distance,
  l'intervalle initial et la diminution par répétition en minutes et secondes.

- **EF-03 — Aperçu calculé**  
  Avant l'enregistrement, l'application affiche chaque répétition avec son
  numéro, sa distance, son intervalle et son heure relative de départ.

- **EF-04 — Validation immédiate**  
  Le formulaire indique précisément le champ invalide et empêche
  l'enregistrement d'une cadence impossible.

- **EF-05 — Planning immuable au départ**  
  Après le démarrage, les paramètres de cadence sont figés. Une correction de
  temps ne déplace pas rétroactivement les départs déjà planifiés.

- **EF-06 — Départ automatique**  
  Le départ suivant est déclenché à partir de l'heure réelle de lancement de la
  série et du cumul des intervalles, et non à partir de l'heure de fin du
  participant précédent.

- **EF-07 — Compteurs distincts**  
  L'interface distingue visuellement le temps d'effort, le temps restant avant
  le prochain départ et la récupération calculée après l'arrivée.

- **EF-08 — Enregistrement des temps**  
  Le coach peut enregistrer un temps pour chaque participant et chaque
  répétition, puis le corriger avec la traçabilité déjà attendue pour les
  résultats.

- **EF-09 — Reprise fiable**  
  Après fermeture, changement d'onglet ou perte temporaire de réseau, l'écran
  recalcule la répétition et les compteurs depuis les échéances enregistrées,
  sans redémarrer un chronomètre local à zéro.

- **EF-10 — Prévention des doubles actions**  
  Un double appui ne peut ni démarrer deux fois une série, ni créer deux temps
  pour le même participant et la même répétition.

- **EF-11 — États d'interface**  
  L'écran prévoit les états chargement, prêt, compte à rebours, effort,
  récupération, retard, pause éventuelle, terminé, erreur et reprise.

- **EF-12 — Lecture athlète**  
  L'athlète affecté peut voir le détail de la série, la répétition courante, le
  prochain départ et ses temps enregistrés, en lecture seule.

- **EF-13 — Accessibilité des alertes**  
  Les changements de répétition utilisent au minimum un signal visuel et un
  retour accessible. Le son et la vibration doivent pouvoir être activés ou
  désactivés selon les capacités de la plateforme.

## 7. Règles métier et autorisations

- **RM-01**  
  Toutes les durées sont stockées en secondes entières positives. L'interface
  les affiche au format `m:ss`.

- **RM-02**  
  Pour une dégression linéaire, l'intervalle de la répétition `i` est :

  ```text
  intervalle(i) = intervalle_initial - (i - 1) × diminution
  ```

- **RM-03**  
  Chaque intervalle calculé doit être strictement supérieur à zéro.

- **RM-04**  
  L'heure relative de départ de la répétition `i` est la somme des intervalles
  précédents. La répétition 1 part à `T+0`.

- **RM-05**  
  La récupération individuelle est :

  ```text
  récupération = max(0, prochain_départ_prévu - heure_arrivée)
  ```

  Une récupération n'est jamais affichée comme une durée négative.

- **RM-06**  
  Le serveur constitue la référence pour l'heure de lancement, les paramètres et
  les temps enregistrés. L'horloge locale sert uniquement à l'affichage entre
  deux synchronisations.

- **RM-07**  
  Seul le coach responsable de la compétition peut créer, modifier, lancer,
  terminer ou corriger une série. Les contrôles doivent exister côté serveur et
  dans les politiques RLS, pas seulement dans l'interface.

- **RM-08**  
  Un athlète ne peut lire que les séries auxquelles il est autorisé à accéder et
  ne peut pas modifier les temps officiels.

- **RM-09**  
  Une série commencée ne peut être supprimée. Son annulation conserve le planning
  et les temps déjà enregistrés pour l'historique.

- **RM-10 — Hypothèse à confirmer**  
  La diminution s'applique après chaque répétition, y compris pour calculer
  l'intervalle affiché sur la dernière répétition. Ce dernier intervalle n'a pas
  de départ suivant mais reste une durée cible utile.

## 8. Exemple de calcul

### Hypothèse proposée : 5 × 500 m, départ 3:00, diminution 0:15

| Répétition | Intervalle | Départ relatif | Départ suivant |
|---:|---:|---:|---:|
| 1 | 3:00 | T+0:00 | T+3:00 |
| 2 | 2:45 | T+3:00 | T+5:45 |
| 3 | 2:30 | T+5:45 | T+8:15 |
| 4 | 2:15 | T+8:15 | T+10:30 |
| 5 | 2:00 | T+10:30 | fin de série |

Si la répétition 1 est terminée en 2:20, la récupération est de 0:40.  
Si la répétition 2 est terminée en 2:20, la récupération est de 0:25.

Pour **10 × 1 000 m**, le même calcul est appliqué avec les valeurs configurées.
La cadence exacte de cet exemple reste à fournir.

## 9. Données et intégrations

Modèle fonctionnel proposé, indépendant du choix SQL final :

### Série

- identifiant ;
- épreuve ou compétition parente ;
- nom ;
- nombre de répétitions ;
- distance en mètres ;
- intervalle initial en secondes ;
- diminution en secondes ;
- politique de dépassement ;
- heure réelle de lancement ;
- statut : brouillon, prête, en cours, terminée ou annulée ;
- coach responsable ;
- dates de création et modification.

### Répétition

- identifiant de série ;
- numéro ;
- intervalle calculé ;
- départ relatif calculé ;
- heure de départ prévue ;
- heure de départ effective ;
- statut.

### Temps individuel

- répétition ;
- participant ;
- temps brut en millisecondes ;
- heure d'arrivée ;
- statut éventuel ;
- correction et révision ;
- auteur et date de la dernière modification.

Une migration Supabase sera nécessaire. Elle devra préserver les manches
existantes et empêcher les doublons sur le couple répétition/participant.

## 10. Critères d'acceptation

- **CA-01 — EF-02, RM-02, RM-03**  
  Étant donné 5 répétitions, un intervalle initial de 3:00 et une diminution de
  0:15, quand le coach affiche l'aperçu, alors les intervalles sont 3:00, 2:45,
  2:30, 2:15 et 2:00.

- **CA-02 — EF-03, RM-04**  
  Avec la même configuration, les départs relatifs affichés sont T+0:00,
  T+3:00, T+5:45, T+8:15 et T+10:30.

- **CA-03 — EF-04, RM-03**  
  Étant donné une configuration dont un intervalle calculé vaut zéro ou moins,
  quand le coach enregistre, alors l'opération est refusée et la première
  répétition invalide est indiquée.

- **CA-04 — EF-06**  
  Étant donné une série lancée à 10:00:00, quand aucun temps n'est encore saisi,
  alors le départ de la répétition 2 reste prévu à 10:03:00.

- **CA-05 — EF-07, RM-05**  
  Étant donné une arrivée à T+2:20 pour un prochain départ à T+3:00, alors
  l'interface affiche 0:40 de récupération.

- **CA-06 — EF-05, EF-08**  
  Quand un coach corrige après coup le temps de la répétition 1, alors le départ
  prévu de la répétition 2 ne change pas.

- **CA-07 — EF-09**  
  Étant donné une application rouverte pendant la répétition 3, alors la
  répétition active et le temps restant sont reconstruits depuis les données
  persistées avec au plus l'écart lié à la précision d'affichage.

- **CA-08 — EF-10**  
  Quand le coach appuie deux fois rapidement sur « Lancer », alors une seule
  transition de démarrage et un seul planning sont enregistrés.

- **CA-09 — EF-12, RM-08**  
  Un athlète affecté peut lire le planning et ses temps, mais toute tentative de
  modification côté serveur est refusée.

- **CA-10 — EF-01**  
  Une manche classique continue d'utiliser son délai après première arrivée et
  ne présente aucun champ de cadence dégressive.

## 11. Scénarios de recette

1. Créer et terminer une série 5 × 500 m en 3:00, -0:15.
2. Prévisualiser une série 10 × 1 000 m avec des valeurs réalistes confirmées.
3. Refuser une dégression qui produit un intervalle nul avant la fin.
4. Enregistrer une arrivée avant le prochain départ et vérifier la récupération.
5. Enregistrer une arrivée après le prochain départ et vérifier la politique de
   dépassement retenue.
6. Fermer et rouvrir Android pendant un compte à rebours.
7. Recharger la page web pendant un compte à rebours.
8. Couper puis rétablir le réseau autour d'une échéance de départ.
9. Tester deux appareils coach ouverts simultanément.
10. Vérifier les droits d'un athlète affecté, non affecté et d'un autre coach.

## 12. Propositions techniques

Ces éléments sont des pistes, pas des décisions métier :

- ajouter un agrégat de domaine dédié à la série plutôt que détourner
  `dureeLimiteSecondes` ;
- calculer le planning dans un service de domaine pur et entièrement testable ;
- faire démarrer/avancer la série par une fonction Supabase transactionnelle et
  idempotente ;
- persister les échéances absolues afin que les chronomètres Android et web
  puissent se reconstruire ;
- conserver les couches hexagonales : entités et calculs dans `domain`, cas
  d'utilisation dans `application`, Supabase dans `infrastructure`, écrans
  et compteurs dans `presentation` ;
- documenter toute migration dans un fichier d'instructions avant son exécution.

## 13. Questions et décisions à confirmer

1. **Sens exact de « départ 3 min »** : confirme-t-on que la répétition 1 part à
   T+0 et que la répétition 2 part exactement à T+3:00 ?
2. **Dégression** : est-elle toujours régulière, par exemple -15 s à chaque fois,
   ou faut-il pouvoir saisir chaque intervalle manuellement ?
3. **Dépassement** : si un athlète met plus longtemps que l'intervalle prévu,
   doit-il repartir immédiatement, manquer la répétition, être marqué en retard
   ou attendre une action du coach ?
4. **Départ collectif ou individuel** : tous les participants partent-ils
   ensemble à chaque répétition, ou faut-il conserver l'ordre de départ actuel ?
5. **Finalité** : ces séries sont-elles des épreuves officielles avec classement
   et publication, ou des séances d'entraînement avec suivi individuel ?
6. **Alertes** : faut-il un signal à 10 s, 5 s puis au départ, avec son et
   vibration ?
7. **Pause** : le coach doit-il pouvoir mettre la série en pause ? Si oui, les
   échéances futures sont-elles toutes décalées ?
8. **Dernière répétition** : l'intervalle de la dernière doit-il servir de délai
   maximal d'arrivée ou uniquement de cible informative ?
9. **10 × 1 000 m** : quels sont l'intervalle initial et la diminution souhaités ?
