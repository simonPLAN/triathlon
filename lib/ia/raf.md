# Reste à faire — Fonctionnalités et publication Android

Ce document regroupe les fonctionnalités manquantes ou partielles relevées lors de la revue du code.
Les cases ci-dessous restent ouvertes ; les migrations fournies ne sont pas considérées comme déployées sans vérification sur Supabase.


## État de la revue du dépôt

Revue du 2 novembre 2026. Les constats portent sur le code et les fichiers locaux, pas sur les réglages effectivement déployés dans Supabase ou la Play Console.

| Sujet | Présent dans le code | Reste à faire ou à vérifier |
|---|---|---|
| Comptes | Inscription, connexion, déconnexion, messages de confirmation d'e-mail | Récupération du mot de passe, parcours de confirmation complet, suppression de compte |
| Rôles | Deux rôles `athlete` et `coach`, accueil séparé via `AuthGate` | Audit serveur des droits, attribution du rôle coach, décision sur arbitre/administrateur |
| Interface | Thème clair/sombre, composants communs, recherche d'athlètes, confirmations et chargements sur plusieurs écrans | Harmonisation des écrans restants, identité définitive, recette sur appareils réels |
| Fonctionnel sportif | Premier arrivé, compte à rebours, résultats, hors délai, enchaînement et publication implémentés | Compléments détaillés ci-dessous ; ne pas refaire ces fonctions déjà présentes |
| Supabase | Trois migrations avec RPC et certaines policies | Schéma initial complet non fourni par ces migrations ; vérifier RLS, policies existantes et déploiement réel |
| Tests | Tests métier, contrôleurs, widgets et échange HTTP local des horaires | Tests avec une vraie base Supabase, tests de bout en bout et recette Release |
| Identifiant Android | `com.example.triathlon` | Choisir l'identifiant définitif avant publication |
| Signature Release | `signingConfig = signingConfigs.getByName("debug")` | Configurer une clé d'upload de production |
| Version | `1.0.0+1`, transmise à Gradle depuis Flutter | Définir la version de lancement et la stratégie d'incrémentation |
| API cible | `targetSdk = flutter.targetSdkVersion` | Vérifier la valeur résolue dans l'artefact Release, pas seulement dans le fichier Gradle |
| Icône | Ressources `ic_launcher` et icône adaptative présentes | Valider l'identité graphique, le rendu et les visuels Store |
| Démarrage | Ressource `launch_background.xml` avec fond blanc de base | Personnaliser et vérifier le splash selon les versions Android |
| Réseau | Permission `INTERNET` présente dans le manifeste principal | Tester les requêtes sur la version Release et les pertes de connexion |
| Secrets | `main.dart` utilise une clé publique publishable ; aucune référence à une clé service_role trouvée dans le code Dart inspecté | Auditer aussi les artefacts, fichiers suivis et l'historique ; séparer staging et production |
| Clés de signature dans Git | `android/.gitignore` exclut déjà `key.properties`, `*.jks` et `*.keystore` | Vérifier qu'aucune clé n'a déjà été suivie/committée et sécuriser les sauvegardes |

Les fonctions « déjà présentes » restent à valider en conditions réelles. Les tests locaux de la dernière implémentation ont annoncé 34 tests réussis ; cette revue documentaire ne les a pas relancés.

## Côté coach

### Participants et départs — priorité haute

- [ ] Sélectionner les participants de chaque manche, au lieu d'utiliser systématiquement tous les inscrits à la compétition.
- [ ] Enregistrer les affectations aux manches et les retrouver après rechargement.
- [ ] Définir l'ordre de départ des athlètes, indépendamment de l'ordre des épreuves et des manches.
- [ ] Adapter la grille des arrivées et le marquage hors délai aux seuls participants affectés à la manche.

### Configuration des manches

- [ ] Permettre une configuration individuelle par manche lorsque nécessaire ; actuellement le nombre de manches et le délai sont définis par épreuve.
- [ ] Préciser les paramètres individuels autorisés et leurs règles de modification avant/après le départ.

### Pénalités, bonus et statuts — priorité haute

- [ ] Ajouter les pénalités et les bonus avec un motif.
- [ ] Définir leur effet : modification du temps, des points ou des deux.
- [ ] Recalculer les classements concernés après chaque ajustement.
- [ ] Permettre de déclarer un abandon ou une disqualification avant l'arrivée, directement depuis un participant sans résultat.
- [ ] Conserver l'action existante de changement de statut sur un résultat déjà enregistré.

### Saisie et correction des résultats — priorité haute

- [ ] Permettre la saisie manuelle d'un temps et sa correction.
- [ ] Permettre un changement de position avec décalage ou échange automatique des autres places.
- [ ] Recalculer les positions, points et écarts des résultats affectés.
- [ ] Garantir la cohérence des corrections dans une transaction, sans positions dupliquées.
- [ ] Définir le traitement des résultats déjà publiés lorsqu'ils sont corrigés.

### Validation et publication

- [ ] Ajouter une étape explicite de validation avant publication ; actuellement la publication est accessible après la fin de la manche.
- [ ] Définir le verrouillage des résultats validés et les conditions de réouverture pour correction.
- [ ] Distinguer clairement les résultats provisoires, validés et publiés dans l'interface.

### Classements

- [ ] Harmoniser les règles de classement et de départage entre les vues coach et athlète.
- [ ] Définir les critères de départage au-delà du total des points, si nécessaire.
- [ ] Présenter explicitement les niveaux manche, épreuve et compétition.
- [ ] Réutiliser les mêmes calculs métier dans toutes les vues, y compris après pénalité, bonus ou correction.

### Clôture et enchaînement hors écran

- [ ] Exécuter la clôture du délai côté serveur pour fonctionner même si l'écran coach n'est pas ouvert ou si l'application est fermée.
- [ ] Marquer uniquement les participants restants de la manche hors délai.
- [ ] Démarrer la manche suivante selon la configuration de la compétition.
- [ ] Synchroniser l'interface à la reprise de l'application.
- [ ] Empêcher les clôtures et démarrages en double, notamment avec plusieurs appareils coach.

## Côté athlète

### Détail d'une compétition — priorité haute

- [ ] Ajouter une page de détail accessible depuis les compétitions disponibles et les compétitions inscrites.
- [ ] Afficher les informations complètes : nom, date, lieu, description et statut.
- [ ] Regrouper l'état de l'inscription, le dossard et les actions autorisées sur cette page.
- [ ] Donner accès au programme et aux résultats publiés depuis cette page.

### Programme : épreuves et manches — priorité haute

- [ ] Afficher les épreuves prévues avant la publication des résultats.
- [ ] Afficher leurs disciplines, distances et ordre.
- [ ] Afficher les manches et leurs statuts : à venir, en cours, terminée ou annulée.
- [ ] Lorsque l'affectation des participants sera disponible, distinguer les manches auxquelles l'athlète participe.
- [ ] Afficher son ordre de départ lorsqu'il est défini.
- [ ] Conserver ces écrans en lecture seule avec des autorisations Supabase adaptées.

### État de l'inscription

- [ ] Afficher explicitement « Non inscrit », « Inscrit » et « Inscriptions fermées » selon la situation.
- [ ] Distinguer une vérification en cours d'une vérification en erreur.
- [ ] Proposer une nouvelle tentative en cas d'erreur, sans laisser l'interface bloquée sur « Vérification de l'inscription… ».
- [ ] Expliquer pourquoi l'inscription ou la désinscription n'est plus autorisée.
- [ ] Actualiser clairement l'état après inscription, désinscription et attribution du dossard.

## Vérifications de livraison communes

- [ ] Vérifier l'application des migrations Supabase fournies sur l'environnement cible.
- [ ] Tester les autorisations avec un coach propriétaire, un autre coach, un athlète inscrit et un athlète non inscrit.
- [ ] Vérifier qu'un athlète ne peut consulter que les résultats autorisés et publiés.
- [ ] Couvrir les nouvelles règles par des tests métier et les nouveaux parcours par des tests d'interface.

## Déjà disponible — à préserver

- Création et modification des compétitions.
- Gestion des épreuves : création, modification, suppression protégée, réorganisation et adaptation des manches, sous réserve de la migration correspondante.
- Génération des manches et gestion de leur cycle.
- Saisie tactile des arrivées, premier arrivé et compte à rebours.
- Clôture automatique à zéro et bascule vers la manche suivante depuis les écrans coach concernés, selon la configuration.
- Correction du statut, de la position et du commentaire d'un résultat existant.
- Publication individuelle et publication groupée des manches terminées d'une épreuve.
- Inscription d'athlètes invités sans compte, sous réserve de la migration correspondante.
- Vue athlète des compétitions ouvertes et de ses compétitions inscrites.
- Inscription et désinscription tant que les inscriptions sont ouvertes.
- Affichage du dossard et de l'inscription confirmée.
- Consultation des résultats publiés et classement général cumulé côté athlète, avec filtre personnel.


## Comptes, authentification et rôles

### Déjà présent dans l'application

- [x] Inscription d'un compte athlète par e-mail et mot de passe.
- [x] Connexion et déconnexion via Supabase Auth.
- [x] Accueil distinct selon les rôles coach et athlète.
- [x] Message après inscription invitant à confirmer l'e-mail et traduction de l'erreur « e-mail non confirmé ».

Références : `lib/domain/ports/auth_repository.dart`, `lib/infrastructure/repositories/supabase/auth_repository_supabase.dart`, `lib/presentation/pages/connexion_page.dart`, `lib/presentation/pages/auth_gate.dart`.

### Récupération du mot de passe — bloquant avant publication

- [ ] Ajouter « Mot de passe oublié » sur la connexion.
- [ ] Implémenter l'envoi du lien, la réception du lien dans l'application et l'écran de nouveau mot de passe.
- [ ] Configurer les URL de redirection et les liens Android pour les environnements de test et de production.
- [ ] Gérer les liens expirés, déjà utilisés ou invalides avec des messages compréhensibles.
- [ ] Tester le parcours depuis un appareil avec et sans session existante.

### Confirmation de l'adresse e-mail

- [ ] Vérifier l'activation de la confirmation dans Supabase ; le message affiché dans Flutter ne prouve pas ce réglage.
- [ ] Ajouter un écran expliquant l'attente de confirmation et permettant de renvoyer l'e-mail.
- [ ] Gérer les liens de confirmation, leur expiration et le retour vers la connexion.
- [ ] Ne pas annoncer une session connectée si seul le compte a été créé.
- [ ] Vérifier les comportements avec confirmation activée et désactivée en staging.
- [ ] Configurer et tester les modèles d'e-mails et le SMTP de production.

### Droits et attribution des rôles

- [ ] Formaliser la matrice des droits pour athlète, coach/arbitre et, seulement si retenu, administrateur.
- [ ] Décider si l'arbitre utilise le rôle coach ou possède des droits délégués ; seul `coach` existe actuellement avec `athlete`.
- [ ] Définir une attribution contrôlée du rôle coach, sans permettre à un utilisateur de s'élever lui-même en coach.
- [ ] Empêcher la modification du rôle via une mise à jour de son propre profil ou des métadonnées utilisateur.
- [ ] Vérifier les autorisations côté serveur sur chaque action ; la séparation des écrans n'est pas une autorisation.
- [ ] Réserver les outils administrateur à un environnement et des autorisations adaptés si ce rôle est ajouté.

### Suppression du compte — bloquant pour un parcours avec création de compte

- [ ] Ajouter un accès clair à « Supprimer mon compte » dans l'application, avec confirmation et vérification de l'identité si nécessaire.
- [ ] Implémenter la suppression via un traitement serveur authentifié ; aucune clé privilégiée dans Flutter.
- [ ] Supprimer le compte Auth et traiter les données associées, pas uniquement la ligne de profil.
- [ ] Définir le devenir des inscriptions, résultats, compétitions d'un coach et profils invités qu'il a créés.
- [ ] Documenter les données supprimées, anonymisées ou conservées pour une obligation applicable et la durée associée.
- [ ] Éviter les suppressions en cascade accidentelles qui détruiraient l'historique sportif d'autres participants.
- [ ] Fournir une page web publique permettant de demander la suppression du compte et des données.
- [ ] Renseigner cette URL dans la Play Console et tester la demande jusqu'à son aboutissement.
- [ ] Invalider la session et effacer les données locales associées après suppression.

Le parcours dans l'application et la ressource web sont à préparer conformément aux [exigences Google Play de suppression de compte](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).

## Interface : stabilisation et identité

Le thème et les composants communs sont déjà présents dans `lib/presentation/theme/` et `lib/presentation/widgets/commun/`. L'accueil par rôle existe ; il reste à finaliser et tester l'ensemble du parcours.

- [ ] Appliquer les composants communs aux écrans qui ont encore leurs propres états vides, erreurs et cartes.
- [ ] Uniformiser les retours, titres, libellés et accès aux compétitions, participants et résultats.
- [ ] Vérifier chaque opération réseau : état en cours visible, bouton désactivé et retour de succès ou d'erreur.
- [ ] Ajouter des gardes dans les méthodes d'action contre les doubles soumissions, y compris au clavier et après réouverture d'un dialogue.
- [ ] Tester les doubles clics sur inscription, arrivée, correction, publication et création.
- [ ] Vérifier toutes les confirmations de suppression et de désinscription ; plusieurs existent déjà.
- [ ] Traduire les erreurs techniques restantes et afficher un chemin de reprise.
- [ ] Vérifier les erreurs avec données déjà affichées : ne pas laisser croire qu'une actualisation a réussi si elle a échoué.
- [ ] Tester les listes vides, filtres sans résultat et chargements sur tous les écrans.
- [ ] Valider définitivement la palette, la typographie, le contraste et le thème sombre.
- [ ] Tester petits téléphones, grands téléphones, paysage, clavier ouvert et grande taille de texte.
- [ ] Vérifier les libellés d'accessibilité, tailles tactiles et annonces utiles avec TalkBack.
- [ ] Confirmer le nom public : `triathlon` dans Android et `Compétition sportive` dans Flutter ne constituent pas encore une identité harmonisée.
- [ ] Valider ou remplacer les icônes déjà présentes ; vérifier les masques adaptatifs et les modes clair/sombre.
- [ ] Personnaliser le splash natif et vérifier l'écran de transition vers Flutter, notamment sur Android 12 et suivants.

## Architecture et cohérence technique

La séparation domaine / cas d'utilisation / infrastructure / présentation existe déjà, mais la refonte de tout le projet n'est pas terminée.

- [ ] Réduire les grandes pages restantes et extraire leurs widgets et états spécialisés.
- [ ] Sortir l'orchestration entre contrôleurs du dashboard dans des cas d'utilisation dépendant des ports.
- [ ] Réutiliser le même calcul de classement pour coach et athlète.
- [ ] Isoler puis supprimer la couche parallèle `domain/models.dart`, `infrastructure/app_repository.dart` et les anciens fichiers `presentation/*_pages.dart`, après vérification de leurs usages.
- [ ] Centraliser la composition des dépendances plutôt que continuer à allonger `main.dart`.
- [ ] Éviter qu'un chargement du dashboard écrase les données partagées des contrôleurs utilisés par un autre écran.
- [ ] Uniformiser les horodatages UTC à l'enregistrement et les heures locales à l'affichage ; des corrections et tests existent déjà.
- [ ] Rendre atomiques les opérations liées : première arrivée + résultat, clôture + hors délai + démarrage suivant, réorganisation des places.
- [ ] Renforcer les protections contre les opérations simultanées de plusieurs coachs et les données périmées dans un écran.

## Supabase : audit de production — bloquant

### Schéma et RLS

Les trois migrations présentes apportent des fonctions et certaines règles. Elles ne prouvent ni l'activation de RLS sur toutes les tables, ni la sécurité des policies existantes dans le projet déployé.

- [ ] Exporter/versionner le schéma initial et les policies existantes afin de pouvoir reconstruire la base à partir du dépôt.
- [ ] Vérifier et activer RLS sur `profils`, `competitions`, `inscriptions`, `epreuves`, `manches` et `resultats`.
- [ ] Appliquer la même démarche aux futures tables de participants, pénalités, bonus et classements.
- [ ] Vérifier séparément SELECT, INSERT, UPDATE et DELETE avec des comptes réels.
- [ ] Autoriser un athlète à modifier uniquement les champs autorisés de son profil, jamais son rôle.
- [ ] Autoriser l'athlète à gérer uniquement sa propre inscription lorsque la compétition le permet.
- [ ] Empêcher l'athlète de modifier dossards, résultats, points et publication.
- [ ] Limiter l'édition des compétitions, épreuves, manches et résultats au coach propriétaire ou à une délégation explicitement prévue.
- [ ] Protéger la publication côté serveur contre un autre coach ou un appel direct.
- [ ] Vérifier que les résultats non publiés ne sont pas lisibles par une requête directe aux tables, même si la RPC athlète filtre correctement.
- [ ] Vérifier la confidentialité des profils invités et leur visibilité dans les listes d'athlètes.
- [ ] Auditer chaque fonction `SECURITY DEFINER` : droits EXECUTE, contrôle de `auth.uid()`, propriétaire, paramètres et `search_path`.
- [ ] Vérifier les contraintes d'unicité : inscription par athlète, dossard par compétition, position par manche, numéro de manche et ordre d'épreuve.
- [ ] Vérifier les clés étrangères, les types de timestamps et les règles de suppression en cascade.
- [ ] Exécuter les migrations sur staging, vérifier leur réexécution prévue et tester la migration depuis une base avec données.
- [ ] Exécuter le Security Advisor et résoudre les alertes pertinentes avant production.

### Authentification, secrets et exploitation

- [ ] Auditer l'ensemble des fichiers suivis, l'historique Git et la build pour les clés privilégiées ou secrets ; aucune clé service_role repérée dans le code Dart inspecté.
- [ ] Garder uniquement la clé publique client dans Flutter ; une clé publique ne remplace pas les règles RLS.
- [ ] Externaliser la configuration Supabase de `main.dart` pour sélectionner explicitement staging ou production.
- [ ] Protéger les comptes d'administration Supabase par MFA et contrôler les accès de l'organisation.
- [ ] Vérifier la confirmation d'e-mail, les expirations des liens et les limites d'envoi.
- [ ] Configurer un SMTP de production et vérifier la délivrabilité des confirmations et récupérations.
- [ ] Retirer les comptes, compétitions et résultats de test de l'environnement de production selon un plan validé.
- [ ] Prévoir sauvegardes, conservation et restauration ; effectuer un essai de restauration.
- [ ] Vérifier les index, performances et quotas avec un volume représentatif de participants et de résultats.
- [ ] Prévoir une surveillance des erreurs serveur et une procédure d'incident sans journaliser de secrets ou de données personnelles inutiles.

À réaliser avec les checklists officielles [sécurité Supabase](https://supabase.com/docs/guides/security/production-checklist) et [production Supabase](https://supabase.com/docs/guides/deployment/going-into-prod).

## Tests et recette complète

### Couverture déjà présente

- [x] Tests de points et de classement général.
- [x] Tests métier d'inscription d'invités et de configuration des épreuves.
- [x] Tests locaux d'horodatage et d'échange HTTP des manches.
- [x] Tests d'interface de publication, enchaînement, répertoire coach, résultats athlète et composants communs.

Ces tests utilisent notamment des faux dépôts ou un serveur HTTP local. Ils ne valident pas les policies ni l'exécution des migrations dans Supabase. Aucun dossier de tests de bout en bout `integration_test` n'a été trouvé lors de cette revue.

### Parcours sur staging et appareils réels

- [ ] Préparer un coach propriétaire, un second coach et au moins deux comptes athlètes.
- [ ] Créer une compétition avec plusieurs épreuves et plusieurs manches.
- [ ] Tester la création de compte, confirmation d'e-mail, connexion, restauration de session et déconnexion.
- [ ] Tester la récupération du mot de passe et la suppression du compte une fois implémentées.
- [ ] Tester inscription, double inscription, désinscription et fermeture des inscriptions.
- [ ] Décider si une capacité maximale est nécessaire ; si oui, définir et tester le cas « compétition complète ».
- [ ] Tester l'ajout d'invités, les doublons de dossard et leur présence dans les résultats.
- [ ] Tester la configuration des épreuves, leur ordre, la réduction/augmentation des manches et la protection des résultats existants.
- [ ] Tester le départ d'une manche, le premier arrivé, le compte à rebours et les arrivées suivantes.
- [ ] Tester la limite exacte du délai, le passage hors délai et le démarrage automatique ou manuel de la suivante.
- [ ] Tester la dernière manche, les manches annulées et l'absence de manche suivante.
- [ ] Tester abandons, disqualifications, correction d'un temps et reclassement selon les fonctions réellement disponibles.
- [ ] Tester publication individuelle/groupée puis lecture par les athlètes inscrits.
- [ ] Comparer les classements coach et athlète sur les mêmes données, y compris les ex aequo.
- [ ] Tester coupure réseau, latence, reprise après échec partiel et absence de doublons après nouvelle tentative.
- [ ] Fermer puis rouvrir l'application pendant la connexion, une inscription et une manche.
- [ ] Tester refus d'accès, session expirée et actions directes par un utilisateur non autorisé.
- [ ] Tester la suppression d'une épreuve ou d'un compte utilisé par d'autres données.
- [ ] Tester les arrivées et corrections concurrentes depuis deux appareils.
- [ ] Conserver un compte-rendu de recette avec appareils, versions, anomalies et corrections.

### Contrôles avant chaque livraison

- [ ] Exécuter les commandes ci-dessous sur la révision destinée à la livraison, avec la configuration de production prévue.
- [ ] Obtenir une analyse sans erreur bloquante et des tests réussis.
- [ ] Vérifier l'absence de crash dans les parcours principaux.
- [ ] Générer le bundle signé puis installer la version distribuée par une piste Google Play.
- [ ] Ajouter une intégration continue pour analyse, tests et contrôle de build.

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Le fichier attendu est normalement `build/app/outputs/bundle/release/app-release.aab`. Les commandes sont une checklist : elles n'ont pas été exécutées dans le cadre de cette mise à jour documentaire.

## Android Release — bloquant avant Google Play

Constats : `android/app/build.gradle.kts` utilise `com.example.triathlon` et signe encore la variante Release avec la configuration debug. `versionName` et `versionCode` proviennent déjà de Flutter. La permission Internet et des icônes adaptatives sont présentes.

- [ ] Choisir l'`applicationId` et le namespace définitifs, puis adapter les références Android nécessaires.
- [ ] Harmoniser le nom Android, le titre Flutter et le nom public de la fiche Store.
- [ ] Définir la version de lancement ; incrémenter le numéro de build à chaque nouvel envoi.
- [ ] Créer et configurer la clé d'upload et Play App Signing.
- [ ] Remplacer la signature debug dans le bloc Release.
- [ ] Conserver la clé et ses mots de passe dans un stockage sécurisé, avec sauvegarde et procédure d'accès.
- [ ] Vérifier que `key.properties` et les keystores restent hors Git ; les règles d'exclusion Android existent déjà.
- [ ] Vérifier le manifeste fusionné Release et ne conserver que les permissions justifiées.
- [ ] Vérifier les logs et retirer les traces de débogage ou données sensibles avant livraison.
- [ ] Vérifier la valeur effective de `targetSdk` ; elle est actuellement héritée de Flutter.
- [ ] Vérifier la compatibilité des dépendances et bibliothèques natives avec les exigences Android/Play applicables à la livraison.
- [ ] Tester la version Release sur appareils et via Google Play, pas uniquement en debug.
- [ ] Prévoir des environnements staging/production et éviter de livrer une build connectée au mauvais projet.

Au 2 novembre 2026, la page officielle consultée indique Android 16 / API 36 ou supérieur pour les nouvelles applications mobiles et mises à jour depuis le 31 août 2026. Revérifier les règles et éventuelles conditions propres à l'application dans la Play Console au moment du dépôt. Sources : [API cible Google Play](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [publication Android Flutter](https://docs.flutter.dev/deployment/android).

## Confidentialité et gestion des données — bloquant

Aucun document de politique de confidentialité nommé comme tel n'a été trouvé dans la recherche de fichiers de cette revue. Une éventuelle page web déjà publiée reste à vérifier séparément.

- [ ] Rédiger et publier une politique de confidentialité accessible sans connexion et référencée dans l'application.
- [ ] Identifier le responsable des données et fournir ses coordonnées et une adresse de contact.
- [ ] Décrire les données collectées : comptes, noms, inscriptions, dossards, temps et résultats.
- [ ] Préciser les finalités, destinataires, prestataires et mesures de protection pertinentes.
- [ ] Définir les durées de conservation et les procédures de suppression/anonymisation, y compris les sauvegardes.
- [ ] Définir le traitement et l'information des athlètes invités qui n'ont pas créé de compte.
- [ ] Prévoir une procédure de demande d'accès, correction ou suppression des données.
- [ ] Décider si le public inclut des mineurs et adapter les règles et déclarations en conséquence.
- [ ] Établir l'inventaire réel des flux de données et SDK pour remplir la section Sécurité des données.
- [ ] Vérifier la cohérence entre l'application, les services tiers, la politique publique et les réponses Play Console.
- [ ] Préparer les conditions d'utilisation si nécessaires au fonctionnement du service.

La politique, les déclarations de confidentialité et les informations d'accès à l'application sont à compléter selon les [instructions Google Play pour la validation](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en).

## Fiche Google Play

Ces éléments ne sont pas vérifiables depuis le seul dépôt et restent à renseigner ou contrôler dans la Play Console.

- [ ] Choisir et renseigner le nom public.
- [ ] Rédiger les descriptions courte et complète.
- [ ] Choisir la catégorie et les coordonnées du développeur.
- [ ] Fournir l'icône haute résolution, les captures d'écran réelles et le visuel promotionnel aux formats demandés.
- [ ] Fournir l'adresse e-mail de contact et l'URL de la politique de confidentialité.
- [ ] Renseigner la classification du contenu, le public cible et la déclaration concernant les publicités.
- [ ] Remplir la section Sécurité des données et la déclaration/URL de suppression de compte.
- [ ] Fournir les instructions d'accès pour l'équipe de validation.
- [ ] Préparer des comptes de démonstration coach et athlète fonctionnels, avec des données permettant de parcourir les écrans.
- [ ] Vérifier que ces accès de démonstration restent utilisables pendant la revue, sans blocage par une confirmation ou un code inaccessible aux validateurs.

## Pistes de test et mise en production

- [ ] Préparer le compte développeur et remplir les éventuelles conditions de vérification et d'accès à la production.
- [ ] Déposer le premier bundle sur une piste de test interne et vérifier l'installation.
- [ ] Organiser un test fermé et appliquer les exigences propres au compte affichées dans la Play Console.
- [ ] Recueillir les retours, corriger les anomalies et contrôler les rapports de tests pré-lancement.
- [ ] Utiliser un test ouvert si utile au projet.
- [ ] Préparer le suivi des crashs/ANR de la version distribuée et un canal de support.
- [ ] Planifier un déploiement progressif avec surveillance et possibilité d'interrompre le déploiement.
- [ ] Valider une procédure de correction urgente et de nouvelle livraison.
- [ ] Réaliser la décision de mise en production après recette fonctionnelle, sécurité serveur, conformité et signature.

## Priorités pour terminer

1. Finaliser récupération du mot de passe, confirmation d'e-mail et suppression de compte.
2. Auditer réellement le schéma, les policies RLS et les droits des RPC sur staging.
3. Compléter les fonctions sportives et le détail athlète recensés plus haut.
4. Stabiliser les parcours réseau, les corrections et la concurrence avec des tests de bout en bout.
5. Finaliser identité, signature Android et bundle Release.
6. Préparer confidentialité, déclarations Store et comptes de démonstration.
7. Passer par les pistes de test avant la production progressive.

Le cycle d'une manche, l'interface du premier arrivé, le compte à rebours, la publication et les classements de base sont déjà codés : leur recette reste nécessaire, mais ils ne sont plus à reconstruire depuis zéro.
