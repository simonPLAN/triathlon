# Spécification — Affiches d'une épreuve

## 1. Statut

**Validée et implémentée localement le 13 novembre 2026. Recette visuelle et déploiement Supabase restant à effectuer.**

Cette spécification formalise la demande exprimée le 13 novembre 2026. Les
décisions de la section 13 ont été validées explicitement par l'utilisateur.

## 2. Objectif

Lors de la création ou de la modification d'une épreuve, le coach peut ajouter
jusqu'à **deux affiches**. Ces affiches sont ensuite visibles dans le détail de
l'épreuve par tous les utilisateurs autorisés à consulter cette épreuve.

Une épreuve peut donc posséder :

- aucune affiche ;
- une affiche principale ;
- une affiche principale et une deuxième affiche.

Les affiches sont facultatives et ne doivent jamais empêcher de consulter les
informations textuelles de l'épreuve.

## 3. Périmètre

### Inclus

- sélection d'une ou deux images depuis Android et le web ;
- aperçu avant l'enregistrement ;
- ajout pendant la création d'une épreuve ;
- ajout, remplacement, réorganisation et suppression pendant la modification ;
- affichage dans les parcours coach et athlète ;
- ouverture d'une affiche en grand ;
- états de chargement, erreur et nouvelle tentative ;
- stockage distant, autorisations et nettoyage des fichiers ;
- texte alternatif pour l'accessibilité.

### Exclus de cette première version

- éditeur d'image intégré ;
- recadrage avancé, filtres ou annotations ;
- galerie de plus de deux images ;
- vidéo, document PDF ou animation ;
- commentaires ou réactions sur une affiche ;
- génération automatique d'affiche ;
- téléchargement explicite dans la galerie de l'appareil ;
- modération automatique du contenu.

### Rôles

- **Coach responsable** : ajoute, remplace, ordonne et supprime les affiches de
  ses propres épreuves.
- **Athlète** : consulte les affiches des épreuves qu'il est autorisé à voir.
- **Autre coach** : peut consulter selon la visibilité de la compétition, mais
  ne peut pas modifier les affiches.
- **Visiteur non connecté** : aucun accès aux affiches dans cette version.

Plateformes : Android et web.

## 4. Existant et écarts

Observations vérifiées :

- l'entité `Epreuve` ne contient actuellement aucune référence d'image ;
- le formulaire de création/modification ne propose pas de média ;
- le programme athlète affiche les données textuelles de l'épreuve ;
- le projet n'utilise actuellement pas Supabase Storage ;
- la documentation de suppression de compte indique qu'un traitement des objets
  Storage devra être prévu si des fichiers sont ajoutés.

Cette fonctionnalité nécessite donc :

- un modèle de média lié à une épreuve ;
- un sélecteur de fichiers compatible Android et web ;
- un stockage d'objets ;
- des politiques Storage et RLS cohérentes ;
- un traitement explicite des fichiers remplacés, supprimés ou abandonnés ;
- l'adaptation des lectures coach et athlète.

## 5. Parcours coach

### 5.1 Création d'une épreuve

1. Le coach remplit les informations habituelles de l'épreuve.
2. Une section **Affiches — facultatif, 2 maximum** est affichée.
3. Il choisit une image depuis son appareil.
4. L'application affiche un aperçu local, le nom du fichier et les actions
   remplacer ou retirer.
5. Il peut ajouter une deuxième image.
6. Il choisit laquelle est l'affiche principale ou réordonne les deux affiches.
7. Il renseigne un texte alternatif pour chaque affiche.
8. Lorsqu'il enregistre, l'interface affiche distinctement la progression de
   l'envoi et empêche un double enregistrement.
9. L'épreuve n'est confirmée qu'une fois les données et les médias enregistrés
   de manière cohérente.
10. En cas d'échec, l'application explique ce qui a échoué et permet de
    réessayer sans perdre les autres champs du formulaire.

### 5.2 Modification

Le coach peut, tant que ses droits sur l'épreuve le permettent :

- ajouter une affiche si moins de deux sont présentes ;
- remplacer une affiche ;
- retirer une affiche ;
- permuter l'affiche principale et la deuxième ;
- modifier le texte alternatif.

Une suppression ou un remplacement demande confirmation si l'affiche est déjà
enregistrée. L'ancien fichier n'est supprimé définitivement qu'après la réussite
de la mise à jour.

## 6. Parcours de consultation

1. L'utilisateur ouvre le détail d'une compétition ou son programme.
2. Chaque épreuve peut présenter une miniature de son affiche principale.
3. Dans le détail de l'épreuve, les affiches sont affichées dans l'ordre défini.
4. Avec deux affiches, l'utilisateur peut passer de l'une à l'autre par un
   composant adapté à la taille de l'écran.
5. Un appui ouvre l'affiche en grand sans masquer définitivement les commandes
   de retour.
6. Si l'image ne charge pas, les informations de l'épreuve restent visibles,
   avec le texte alternatif et une action **Réessayer**.

## 7. Exigences fonctionnelles

- **EF-01 — Section facultative**  
  Le formulaire d'épreuve propose une section d'affiches sans rendre l'ajout
  d'une image obligatoire.

- **EF-02 — Limite de deux**  
  L'interface et le serveur refusent toute troisième affiche pour une même
  épreuve.

- **EF-03 — Sélection compatible**  
  Le coach peut sélectionner un fichier image sur Android et dans un navigateur
  compatible.

- **EF-04 — Contrôle avant envoi**  
  Avant l'envoi, l'application vérifie le type du fichier, sa taille et la
  possibilité de le décoder comme image.

- **EF-05 — Aperçu**  
  Chaque fichier sélectionné est prévisualisé avant l'enregistrement avec son
  ordre et son texte alternatif.

- **EF-06 — Affiche principale**  
  Lorsqu'une épreuve possède au moins une affiche, une seule est identifiée
  comme principale. Avec une seule affiche, elle est automatiquement principale.

- **EF-07 — Réorganisation**  
  Avec deux affiches, le coach peut inverser leur ordre avant ou après
  l'enregistrement.

- **EF-08 — Remplacement sûr**  
  Le coach peut remplacer une affiche sans rendre l'épreuve temporairement
  incohérente ni supprimer l'ancienne image avant la réussite de la nouvelle.

- **EF-09 — Suppression**  
  Le coach peut retirer une affiche après confirmation. Retirer la première
  promeut automatiquement la deuxième comme affiche principale.

- **EF-10 — Progression et double clic**  
  Pendant l'envoi, l'interface affiche une progression ou un état en cours et
  empêche les doubles soumissions.

- **EF-11 — Reprise après erreur**  
  Une erreur réseau ou Storage indique le fichier concerné et permet une
  nouvelle tentative sans effacer les champs textuels de l'épreuve.

- **EF-12 — Affichage universel dans l'application**  
  Tous les utilisateurs disposant du droit de lire l'épreuve voient ses
  affiches sur Android et sur le web.

- **EF-13 — Carte et détail**  
  L'affiche principale peut être utilisée en miniature dans les listes ; les
  deux affiches sont disponibles dans le détail de l'épreuve.

- **EF-14 — Plein écran**  
  L'utilisateur peut agrandir une affiche et revenir au détail de l'épreuve.

- **EF-15 — Chargement non bloquant**  
  Une image lente, absente ou invalide ne bloque ni le texte de l'épreuve ni
  les autres actions autorisées.

- **EF-16 — Accessibilité**  
  Chaque affiche possède un texte alternatif. L'ordre de lecture, le contrôle
  d'agrandissement et le passage entre les affiches sont utilisables avec les
  technologies d'assistance.

- **EF-17 — Actualisation**  
  Après remplacement ou suppression, les écrans actualisés n'affichent plus
  l'ancienne version mise en cache.

- **EF-18 — Suppression liée**  
  La suppression définitive d'une épreuve traite également ses objets Storage,
  sans supprimer les affiches d'une autre épreuve.

- **EF-19 — Droits explicites**  
  Une action indisponible indique qu'un autre coach ou un athlète dispose
  uniquement d'un accès en lecture.

- **EF-20 — Données minimales**  
  Les métadonnées ne conservent pas le chemin local d'origine du fichier ni
  d'informations personnelles inutiles.

## 8. Règles métier et autorisations

- **RM-01**  
  Une épreuve possède entre zéro et deux affiches actives.

- **RM-02**  
  Les positions autorisées sont 1 et 2, uniques par épreuve et sans trou :
  l'affiche en position 1 est l'affiche principale.

- **RM-03**  
  Seul le coach responsable de la compétition parente peut créer, remplacer,
  réordonner ou supprimer les affiches.

- **RM-04**  
  Le droit d'écriture est contrôlé côté serveur, par RLS sur les métadonnées et
  par les politiques Supabase Storage, pas seulement par l'interface.

- **RM-05**  
  Le droit de lecture d'une affiche suit le droit de lecture de son épreuve,
  sauf décision contraire sur l'accès public non connecté.

- **RM-06**  
  Le serveur ne fait pas confiance à l'extension du fichier. Il contrôle le
  type autorisé, la taille et le rattachement de l'objet à l'épreuve.

- **RM-07**  
  Les formats autorisés sont JPEG, PNG et WebP. Le format HEIC est refusé avec
  un message explicite.

- **RM-08**  
  Chaque fichier est limité à 5 Mio et à 4096 × 4096 pixels. Toute orientation
  est acceptée sans recadrage imposé.

- **RM-09**  
  Un fichier est stocké sous un identifiant généré, et non sous son nom fourni
  par l'utilisateur. Le chemin doit inclure ou référencer l'identifiant de
  l'épreuve sans permettre d'accéder à un autre dossier.

- **RM-10**  
  Lors d'un remplacement, la nouvelle image et ses métadonnées sont validées
  avant la suppression de l'ancien objet.

- **RM-11**  
  Un envoi abandonné ne doit pas laisser durablement un objet orphelin. Un
  mécanisme de finalisation ou de nettoyage doit être prévu.

- **RM-12**  
  Le texte alternatif est obligatoire dès qu'une affiche est enregistrée. Il
  décrit le contenu utile sans reprendre uniquement « image » ou « affiche ».

- **RM-13**  
  L'ordre des affiches est stable et identique pour tous les lecteurs.

- **RM-14**  
  Une suppression de compte ne doit pas retirer les affiches conservées avec
  l'historique d'une compétition transférée ou neutralisée. Le traitement suit
  la politique de conservation de la compétition.

- **RM-15**  
  Les contenus envoyés doivent respecter les droits de propriété et ne pas
  exposer de données personnelles sans base appropriée. La validation juridique
  et la procédure de signalement restent à définir.

## 9. Données et intégrations

### Entité fonctionnelle proposée : AfficheEpreuve

- identifiant ;
- identifiant de l'épreuve ;
- position 1 ou 2 ;
- chemin Storage interne ;
- type MIME vérifié ;
- taille en octets ;
- largeur et hauteur si disponibles ;
- texte alternatif ;
- version ou identifiant de cache ;
- auteur de l'envoi ;
- dates de création et modification.

L'URL publique ou signée est une donnée de consultation générée ; elle ne doit
pas nécessairement être conservée comme source métier.

### Contraintes attendues

- unicité `(epreuve_id, position)` ;
- maximum de deux lignes actives par épreuve, garanti côté serveur ;
- rattachement obligatoire à une épreuve existante ;
- contrôle que l'auteur est le coach responsable ;
- position limitée à 1 ou 2 ;
- texte alternatif non vide après normalisation.

### Supabase Storage

Une migration et une configuration Storage seront nécessaires pour :

- créer ou configurer un bucket dédié ;
- limiter les types et tailles autorisés ;
- définir les politiques de lecture, insertion, remplacement et suppression ;
- empêcher un coach d'écrire dans le dossier d'une autre compétition ;
- synchroniser les métadonnées et le cycle de vie des objets ;
- nettoyer les objets orphelins ;
- étendre le parcours de suppression de compte et d'épreuve.

Si les affiches doivent être accessibles sans connexion, un bucket public peut
être envisagé, mais les objets deviennent accessibles à toute personne possédant
l'URL. Si la lecture reste limitée aux utilisateurs autorisés, utiliser un
bucket privé et des URL signées de courte durée est préférable.

## 10. Critères d'acceptation

- **CA-01 — EF-01, RM-01**  
  Étant donné une épreuve sans affiche, quand le coach l'enregistre, alors la
  création réussit et l'épreuve reste consultable.

- **CA-02 — EF-02**  
  Étant donné deux affiches déjà sélectionnées, quand le coach tente d'en
  ajouter une troisième, alors l'action est refusée avec le message
  « Deux affiches maximum par épreuve ».

- **CA-03 — EF-05, EF-06**  
  Quand le coach sélectionne une première image valide, alors son aperçu
  apparaît en position 1 et elle est indiquée comme principale.

- **CA-04 — EF-07, RM-13**  
  Quand le coach inverse deux affiches et enregistre, alors tous les lecteurs
  les voient dans le nouvel ordre après actualisation.

- **CA-05 — EF-08, RM-10**  
  Étant donné une affiche enregistrée, quand le remplacement échoue, alors
  l'ancienne affiche reste visible et aucune métadonnée incohérente n'est
  publiée.

- **CA-06 — EF-09, RM-02**  
  Quand le coach retire l'affiche principale d'une épreuve qui en possède deux,
  alors la deuxième passe en position 1.

- **CA-07 — EF-04, RM-06**  
  Quand un fichier porte une extension d'image mais que son contenu n'est pas
  une image valide, alors l'envoi est refusé.

- **CA-08 — EF-10**  
  Quand le coach appuie deux fois rapidement sur Enregistrer, alors une seule
  création d'épreuve et au plus un envoi par affiche sont finalisés.

- **CA-09 — EF-11**  
  Quand le réseau est interrompu pendant la deuxième affiche, alors l'interface
  identifie cette affiche, conserve le formulaire et propose Réessayer.

- **CA-10 — EF-12, EF-15**  
  Quand une affiche ne peut pas être chargée, alors le détail textuel de
  l'épreuve reste visible et le lecteur peut relancer le chargement.

- **CA-11 — EF-16, RM-12**  
  Quand une affiche ne possède pas de texte alternatif valide, alors
  l'enregistrement final est refusé avec une erreur sur le champ concerné.

- **CA-12 — EF-17**  
  Après remplacement, une actualisation affiche la nouvelle image et non la
  version précédente conservée par le cache.

- **CA-13 — EF-18**  
  Quand une épreuve est supprimée définitivement, alors seuls ses objets sont
  supprimés du bucket et aucune affiche d'une autre épreuve n'est affectée.

- **CA-14 — EF-19, RM-03, RM-04**  
  Quand un athlète ou un autre coach tente une modification directe, alors le
  serveur refuse l'opération.

- **CA-15 — RM-05**  
  Un utilisateur qui peut lire l'épreuve peut charger ses affiches selon la
  règle de visibilité choisie ; un utilisateur non autorisé ne peut pas
  contourner cette règle avec une requête de métadonnées.

## 11. Scénarios de recette

1. Créer une épreuve sans affiche.
2. Créer une épreuve avec une affiche.
3. Créer une épreuve avec deux affiches puis les inverser.
4. Refuser une troisième affiche.
5. Refuser un fichier non image renommé en `.jpg`.
6. Refuser un format ou une taille hors limites une fois celles-ci définies.
7. Couper le réseau pendant le premier puis le second envoi.
8. Fermer le formulaire pendant un envoi.
9. Remplacer une affiche existante avec succès puis avec échec.
10. Supprimer l'affiche principale et vérifier la promotion de la seconde.
11. Consulter sur Android, petit écran web et grand écran web.
12. Tester le texte agrandi et un lecteur d'écran.
13. Tester le cache après remplacement.
14. Tester le coach propriétaire, un autre coach, un athlète autorisé, un
    athlète non autorisé et une session absente.
15. Supprimer une épreuve et vérifier les objets Storage.
16. Tester la suppression du compte du coach selon la politique de conservation.

## 12. Propositions techniques

Ces éléments sont des pistes et non des décisions produit :

- créer une entité `AfficheEpreuve` plutôt que d'ajouter deux URL directement
  dans `Epreuve`, afin de gérer ordre, métadonnées et cycle de vie ;
- ajouter un port de stockage dans le domaine/application sans faire dépendre
  ces couches de Supabase ;
- séparer la création de l'épreuve, l'envoi temporaire et la finalisation par une
  opération idempotente ;
- générer des miniatures ou charger une version adaptée aux listes pour éviter
  de télécharger l'affiche complète sur chaque carte ;
- utiliser une clé de version dans l'URL de consultation pour invalider le cache
  après remplacement ;
- afficher les deux affiches dans un composant accessible sans défilement
  automatique imposé ;
- documenter la migration, le bucket, les politiques et la procédure de retour
  arrière dans un fichier d'instructions dédié.

## 13. Décisions validées

1. Les affiches sont réservées aux utilisateurs authentifiés autorisés à lire
   l'épreuve ; aucun accès anonyme n'est ajouté.
2. Les formats acceptés sont JPEG, PNG et WebP. HEIC est refusé avec une
   explication.
3. Chaque affiche est limitée à 5 Mio et 4096 × 4096 pixels.
4. Toute orientation est acceptée, sans ratio ni recadrage imposé.
5. Le coach saisit un texte alternatif obligatoire de 3 à 300 caractères.
6. Les modifications sont possibles uniquement tant que la compétition est en
   brouillon. La lecture suit ensuite la visibilité de l'épreuve.
7. Les affiches restent consultables pour les compétitions terminées ou
   annulées lorsqu'un utilisateur conserve le droit de lire l'épreuve.
8. Aucun téléchargement explicite vers la galerie de l'appareil n'est prévu en
   première version.
9. Aucun signalement intégré n'est prévu en première version ; le retrait reste
   assuré par le coach responsable pendant le brouillon.
