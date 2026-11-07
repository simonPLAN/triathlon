# Reste à faire — Fonctionnalités et publication Android

Ce document regroupe les fonctionnalités manquantes ou partielles relevées lors de la revue du code.
Les cases cochées correspondent au code et aux tests locaux ; les migrations et réglages serveur ne sont pas considérés comme déployés sans vérification sur Supabase.


## Avancement du 4 novembre 2026

- 119 tests Flutter et 46 tests serveur/SQL réussis ; analyse sans problème au dernier contrôle. APK debug final recompilé avec succès, y compris les ajustements de navigation.
- Cinq nouvelles migrations sont fournies : participants/configuration, cycle atomique, validation, catégories et durcissement RLS. Les tests PGlite/serveur passent avec un runtime Deno local au projet, sans installation globale. Ils ne prouvent pas la compatibilité du schéma Supabase distant ni le déploiement.
- Couleurs bleu marine/orange/blanc adaptées des supports Le Mans Triathlon ; graphiques interactifs réels par épreuve, durées/statuts et alternatives textuelles.
- Catégories facultatives et barème exact fourni par l'organisateur ; aucune valeur inventée pour les tranches absentes. **La formule d'application du coefficient reste à confirmer** ; les classements officiels restent bruts.
- Confirmation d'e-mail, détail athlète, démarrage avec reprise, validation avant publication et protections serveur sont fournis dans le dépôt.
- La planification cron, les migrations réelles, les réglages Auth/SMTP, les données légales, l'identité et la signature Android, les tests appareil et la Play Console restent des étapes externes non réalisées.

Instructions regroupées : [mise à jour BDD et application](../../docs/instructions_mise_a_jour_20261104.md), [coefficients et statistiques](../../docs/coefficients_athletes.md), [RLS et exploitation](../../docs/securite_supabase_production.md).

Les cases cochées ci-dessous concernent le code fourni, pas le déploiement ni la validation de sécurité sur une base réelle.

## État de la revue du dépôt

Revue du 2 novembre 2026. Les constats portent sur le code et les fichiers locaux, pas sur les réglages effectivement déployés dans Supabase ou la Play Console.

| Sujet | Présent dans le code | Reste à faire ou à vérifier |
|---|---|---|
| Comptes | Inscription, connexion, déconnexion, récupération du mot de passe Android avec PKCE ; suppression de compte fournie côté application/serveur/web | Déployer et vérifier la suppression ; héberger la page, renseigner la Play Console ; redirections et vrais e-mails, confirmation complète |
| Rôles | Deux rôles `athlete` et `coach`, accueil séparé via `AuthGate` | Audit serveur des droits, attribution du rôle coach, décision sur arbitre/administrateur |
| Interface | Thème clair/sombre, composants communs, recherche d'athlètes, confirmations et chargements sur plusieurs écrans | Harmonisation des écrans restants, identité définitive, recette sur appareils réels |
| Fonctionnel sportif | Premier arrivé, compte à rebours, résultats, hors délai, enchaînement et publication implémentés | Compléments détaillés ci-dessous ; ne pas refaire ces fonctions déjà présentes |
| Supabase | Onze migrations, dont participants, validation, catégories et durcissement RLS | Schéma initial complet non fourni par ces migrations ; vérifier RLS, policies existantes et déploiement réel |
| Tests | Tests métier, contrôleurs, widgets et échange HTTP local des horaires | Tests avec une vraie base Supabase, tests de bout en bout et recette Release |
| Identifiant Android | `com.example.triathlon` | Choisir l'identifiant définitif avant publication |
| Signature Release | Signature upload uniquement, sans repli debug ; configuration locale/coffre et script fournis | Confirmer/créer la clé, sauvegarder les secrets, activer Play App Signing et produire le bundle |
| Version | `1.0.0+1`, transmise à Gradle depuis Flutter | Définir la version de lancement et la stratégie d'incrémentation |
| API cible | targetSdk explicite 36 ; modèle Gradle vérifié : compileSdk 36, minSdk 24, NDK 28.2.13676358 | Vérifier l'artefact Release final, les bibliothèques natives et les pages 16 Ko |
| Icône | Ressources `ic_launcher` et icône adaptative présentes | Valider l'identité graphique, le rendu et les visuels Store |
| Démarrage | Splash bleu marine, ressources Android 12+, écran Flutter de chargement/erreur avec reprise | Recette visuelle sur appareils selon les versions Android |
| Réseau | Permission `INTERNET` présente dans le manifeste principal | Tester les requêtes sur la version Release et les pertes de connexion |
| Secrets | `main.dart` utilise une clé publique publishable ; aucune référence à une clé service_role trouvée dans le code Dart inspecté | Auditer aussi les artefacts, fichiers suivis et l'historique ; séparer staging et production |
| Clés de signature dans Git | `android/.gitignore` exclut déjà `key.properties`, `*.jks` et `*.keystore` | Vérifier qu'aucune clé n'a déjà été suivie/committée et sécuriser les sauvegardes |

Les fonctions « déjà présentes » restent à valider en conditions réelles. Derniers contrôles effectués pendant les implémentations : **94 tests Flutter réussis**, **29 tests serveur/SQL réussis** et `flutter analyze` sans problème. Les tests serveur/SQL s'exécutent localement avec des services simulés et PostgreSQL embarqué PGlite ; ils ne prouvent pas le déploiement ni les réglages du projet Supabase. Analyse et 94 tests Flutter relancés pendant la préparation Android Release ; les 29 tests serveur/SQL correspondent au contrôle antérieur.

Dernières avancées :

- Récupération du mot de passe fournie ; réception d'un e-mail constatée par l'utilisateur, retour Android à vérifier pendant la recette de release.
- Suppression de compte fournie dans Flutter, côté serveur et dans une page web à héberger.
- États d'inscription explicites, reprise après erreur et actualisation du dossard.
- Saisie manuelle, reclassement transactionnel et retrait de publication après correction.
- Actualisation des résultats athlète sans changement d'onglet, avec conservation des filtres.
- Programme des épreuves/manches accessible avant publication, avec lecture seule et contrôles Supabase fournis ; affectations et départs personnels en attente de leur module de gestion.
- Préparation Android Release : flavors isolés, signature upload et contrôles de configuration, titre harmonisé par configuration, scripts de clé/build et guide ; identité définitive et opérations Play encore attendues.

## Côté coach

### Participants et départs — priorité haute

- [x] Sélectionner explicitement les participants de chaque manche ; migration 202611040001 fournie, à tester sur staging.
- [x] Fournir la persistance des affectations et leur relecture (RPC contrôlée).
- [x] Définir l'ordre de départ indépendamment de l'ordre des épreuves et des manches.
- [x] Limiter la grille des arrivées et les hors délai aux participants affectés ; protections client et serveur fournies.

### Configuration des manches

- [x] Configurer le délai individuel et les participants d'une manche avant son départ.
- [x] Fournir le verrouillage de la configuration après départ dans la RPC.

### Pénalités, bonus et statuts — priorité haute

- [x] Ajouter pénalités/bonus de temps avec motif sur les résultats arrivés ; conserver l'ajustement dans le commentaire.
- [x] Définir l'effet retenu : ajout/retrait d'un temps, puis reclassement et recalcul des points ; pas de bonus arbitraire de points.
- [x] Utiliser la correction transactionnelle existante après ajustement du temps.
- [x] Fournir la déclaration d'abandon/disqualification avant arrivée, avec motif et contrôle serveur.
- [x] Conserver le changement de statut sur un résultat existant dans le formulaire de correction d'une manche terminée.

### Saisie et correction des résultats — priorité haute

- [x] Permettre la saisie manuelle d'un temps et sa correction sur une manche terminée (minutes:secondes.millisecondes).
- [x] Proposer décalage des places, échange de deux places ou classement par temps.
- [x] Recalculer les positions, points et écarts du classement complet ; conserver les temps des autres athlètes lors d'un changement de place.
- [x] Fournir une RPC transactionnelle avec verrouillage, contrôle de révision et unicité des places ; tests locaux de rollback et de conflits.
- [x] Retirer toute la manche de la publication après confirmation lorsqu'un résultat publié est corrigé ; imposer une republication explicite.
- [ ] Déployer la migration 202611020005 et vérifier les contraintes, policies et RPC sur le schéma réel.
- [ ] Tester la correction depuis deux appareils et la visibilité athlète après dépublication/republication.

Règles, formats, concurrence et déploiement : [correction_resultats.md](../../docs/correction_resultats.md).

### Validation et publication

- [x] Fournir une validation explicite avant publication, associée à la révision courante du classement (migration 202611040003).
- [x] Définir la réouverture : une correction invalide la révision validée et exige une nouvelle validation/publication.
- [x] Distinguer les états provisoire, validé et publié dans l'interface des manches.

### Classements

- [x] Réutiliser CalculClassementGlobal côté coach et athlète, avec rangs ex aequo sur les points.
- [x] Conserver le même rang à points égaux ; nom puis identifiant stabilisent uniquement l'ordre d'affichage.
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

- [x] Fournir le détail d'une compétition côté athlète depuis les listes ouvertes et inscrites.
- [x] Afficher nom, date, lieu, description et statut dans le détail athlète.
- [x] Regrouper état de l'inscription, dossard et actions permises sur le détail.
- [x] Donner accès au programme et aux résultats publiés depuis le détail athlète.

### Programme : épreuves et manches — priorité haute

- [x] Afficher les épreuves avant publication de résultats, depuis « Voir le programme » sur les compétitions ouvertes et inscrites.
- [x] Afficher la discipline, la distance en mètres et l'ordre des épreuves ; trier les manches par numéro.
- [x] Afficher les statuts À venir, En cours, Terminée et Annulée.
- [x] Préparer l'affichage de la participation personnelle lorsque la source fournit une affectation ; distinguer explicitement la participation inconnue.
- [x] Afficher l'ordre de départ lorsqu'il est fourni et « Ordre de départ non défini » sinon.
- [x] Fournir la table participants_manche et raccorder la RPC du programme aux affectations et ordres réels.
- [x] Fournir une page de programme en lecture seule, une RPC contrôlée et des restrictions RLS sur les lectures/écritures des épreuves et manches.
- [x] Gérer chargement, erreur/réessai, programme vide et actualisation par bouton, glissement ou reprise.
- [ ] Déployer la migration 202611020006 et vérifier les policies du schéma réel, notamment les accès conservés du coach.
- [ ] Tester sur deux appareils le changement d'un statut côté coach puis l'actualisation du programme côté athlète.

La source actuelle renvoie participation et ordre de départ à null : l'inscription à une compétition ne constitue pas une affectation à une manche. Les affichages futurs sont testés avec des données simulées. Règles et déploiement : [programme_athlete.md](../../docs/programme_athlete.md).

### État de l'inscription

- [x] Afficher explicitement « Non inscrit », « Inscrit » et « Inscriptions fermées » selon la situation.
- [x] Distinguer une vérification en cours d'une vérification en erreur, séparément pour chaque compétition.
- [x] Proposer une nouvelle tentative après erreur ou délai de lecture dépassé (20 secondes), sans chargement permanent.
- [x] Expliquer la fermeture selon le statut (préparation, commencée, terminée, annulée) et empêcher les actions devenues interdites.
- [x] Actualiser l'état après inscription/désinscription et changement du dossard ; relire les données avec Actualiser, le glissement de la liste ou à la reprise de l'application. Protéger les données confirmées des réponses anciennes.
- [x] Conserver l'état confirmé et signaler une erreur si l'actualisation des listes échoue après une action réussie.
- [ ] Vérifier ce parcours avec une vraie base et deux appareils (attribution du dossard par le coach puis actualisation côté athlète).

### Actualisation des résultats et classements

- [x] Recharger les résultats avec le bouton Actualiser sans changer d'onglet.
- [x] Actualiser par glissement de la liste, y compris lorsqu'elle est vide.
- [x] Recharger au retour dans l'application.
- [x] Conserver la vue Général / Par manche et le filtre personnel après actualisation.
- [x] Afficher le chargement et empêcher les requêtes simultanées de rafraîchissement.
- [x] Afficher une erreur avec nouvelle tentative en cas d'échec ou de délai dépassé.
- [x] Retirer les anciens résultats de l'écran lorsque la nouvelle lecture ne renvoie plus de résultats publiés.
- [x] Couvrir ces parcours par des tests d'interface, sans changement d'onglet pour forcer le réaffichage.
- [ ] Vérifier avec deux appareils qu'une publication, correction ou dépublication du coach est reflétée côté athlète après actualisation.

Références : `lib/presentation/controllers/resultats_athlete_controller.dart`, `lib/presentation/pages/athlete/resultats_athlete_page.dart`, `test/presentation/resultats_athlete_page_test.dart`. Le rechargement est déclenché par une action ou la reprise de l'application ; la synchronisation continue en temps réel n'est pas implémentée.

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
- Saisie et correction du temps, du statut, de la place et du commentaire sur une manche terminée ; décalage, échange ou tri par temps dans une transaction, sous réserve de la migration 202611020005.
- Retrait de publication de la manche après correction de résultats publiés, puis republication explicite.
- Publication individuelle et publication groupée des manches terminées d'une épreuve.
- Inscription d'athlètes invités sans compte, sous réserve de la migration correspondante.
- Vue athlète des compétitions ouvertes et de ses compétitions inscrites.
- Inscription et désinscription tant que les inscriptions sont ouvertes.
- Affichage du dossard et de l'inscription confirmée.
- Consultation des résultats publiés et classement général cumulé côté athlète, avec filtre personnel.
- Programme côté athlète : épreuves, disciplines, distances, ordre et statuts de manches avant publication des résultats, sous réserve de la migration 202611020006.
- Actualisation des résultats athlète par bouton, glissement et reprise de l'application, sans changement d'onglet ; gestion des erreurs et conservation des filtres.


## Comptes, authentification et rôles

### Déjà présent dans l'application

- [x] Inscription d'un compte athlète par e-mail et mot de passe.
- [x] Connexion et déconnexion via Supabase Auth.
- [x] Accueil distinct selon les rôles coach et athlète.
- [x] Message après inscription invitant à confirmer l'e-mail et traduction de l'erreur « e-mail non confirmé ».

Références : `lib/domain/ports/auth_repository.dart`, `lib/infrastructure/repositories/supabase/auth_repository_supabase.dart`, `lib/presentation/pages/connexion_page.dart`, `lib/presentation/pages/auth_gate.dart`.

### Récupération du mot de passe — bloquant avant publication

- [x] Ajouter « Mot de passe oublié » sur la connexion.
- [x] Implémenter l'envoi du lien, la réception Android à froid/à chaud et l'écran de nouveau mot de passe avec PKCE.
- [x] Déclarer les liens Android et sélectionner les URL de retour selon APP_ENV (production/staging).
- [ ] Renseigner et vérifier les URL autorisées dans chaque projet Supabase et tester le SMTP.
- [x] Gérer les liens expirés, déjà utilisés ou invalides avec des messages compréhensibles.
- [x] Ajouter des tests automatisés des parcours avec et sans session simulée, du formulaire et des doubles envois.
- [ ] Tester le parcours depuis un appareil réel avec et sans session existante et un véritable e-mail.

Configuration et recette : [recuperation_mot_de_passe.md](../../docs/recuperation_mot_de_passe.md).

### Confirmation de l'adresse e-mail

- [ ] Vérifier l'activation de la confirmation dans Supabase ; le message affiché dans Flutter ne prouve pas ce réglage.
- [x] Fournir l'écran d'attente de confirmation avec renvoi contrôlé de l'e-mail.
- [x] Fournir la réception PKCE des liens de confirmation, erreurs et retour vers la connexion ; recette e-mail réel encore nécessaire.
- [x] Conserver le parcours d'attente tant qu'aucune session n'est établie.
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

- [x] Ajouter un accès « Supprimer mon compte » aux espaces coach et athlète, avec confirmation et mot de passe vérifié côté serveur.
- [x] Implémenter le traitement serveur authentifié sans clé privilégiée dans Flutter ; refuser les identifiants de cible injectés et le contournement MFA.
- [x] Fournir la suppression Auth et le nettoyage transactionnel du profil, inscriptions et résultats personnels.
- [x] Définir le devenir des compétitions : archivage sous responsable technique sans Auth, annulation des compétitions actives ; conserver les autres sportifs et invités.
- [x] Documenter les données effacées et conservées, sans supposer une obligation légale de conservation.
- [ ] Valider et publier les durées réelles des sauvegardes/journaux et la politique sportive des autres participants ; compléter le contact de support.
- [x] Ajouter les protections contre les cascades inconnues et les tests PostgreSQL d'atomicité et de conservation des autres participants.
- [x] Créer la page web de suppression utilisable sans application, avec authentification et appel du même serveur.
- [ ] Déployer la migration 202611020004 et la fonction supprimer-compte sur staging puis production ; tester les FK, triggers et policies réels.
- [ ] Héberger la page en HTTPS sur une URL publique et renseigner cette URL dans la Play Console.
- [ ] Tester la demande jusqu'à son aboutissement avec de vrais comptes et vérifier anciens JWT/refresh tokens.
- [x] Fermer la session, retirer la session persistée et vider le répertoire local après suppression confirmée ; proposer une reprise du nettoyage sans seconde suppression.

Implémentation, traitement des données, déploiement et recette : [suppression_compte.md](../../docs/suppression_compte.md).

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
- [ ] Confirmer le nom public définitif ; Android et Flutter utilisent désormais la configuration commune de livraison (nom provisoire Triathlon), avec vérification de correspondance en Release.
- [ ] Valider ou remplacer les icônes déjà présentes ; vérifier les masques adaptatifs et les modes clair/sombre.
- [ ] Personnaliser le splash natif et vérifier l'écran de transition vers Flutter, notamment sur Android 12 et suivants.

## Architecture et cohérence technique

La séparation domaine / cas d'utilisation / infrastructure / présentation existe déjà, mais la refonte de tout le projet n'est pas terminée.

- [ ] Réduire les grandes pages restantes et extraire leurs widgets et états spécialisés.
- [x] Injecter ConsulterResultatsCompetition dans la composition de production ; lecture par les ports sans modifier les états des écrans sportifs.
- [x] Réutiliser CalculClassementGlobal dans les deux vues, y compris pour les ex aequo.
- [ ] Isoler puis supprimer la couche parallèle `domain/models.dart`, `infrastructure/app_repository.dart` et les anciens fichiers `presentation/*_pages.dart`, après vérification de leurs usages.
- [x] Centraliser les dépendances dans lib/composition/assembler_application.dart ; main.dart ne gère que le démarrage.
- [x] Isoler le chargement du dashboard injecté des listes partagées épreuves/manches/résultats.
- [ ] Uniformiser les horodatages UTC à l'enregistrement et les heures locales à l'affichage ; des corrections et tests existent déjà.
- [x] Fournir la réorganisation atomique des places, points et écarts via la RPC de correction avec contrôle de révision.
- [ ] Rendre atomiques les autres opérations liées : première arrivée + résultat, clôture + hors délai + démarrage suivant.
- [ ] Renforcer les protections contre les opérations simultanées de plusieurs coachs et les données périmées dans un écran.

## Supabase : audit de production — bloquant

### Schéma et RLS

Les six migrations présentes apportent des fonctions et certaines règles. Elles ne prouvent ni l'activation de RLS sur toutes les tables, ni la sécurité des policies existantes dans le projet déployé.

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
- [x] Isoler la sélection staging/production dans `ConfigurationAuthentification`, avec `APP_ENV`, `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY`.
- [x] Fournir les flavors Android production/staging, installations côte à côte, contrôles de cohérence APP_ENV/flavor, nom et projet Supabase ; interdire les clés privilégiées et toute configuration Release implicite.
- [ ] Configurer le vrai projet staging et vérifier les redirections et l'isolation sur appareils. Le repli public production subsiste seulement pour le debug.
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
- [x] Tests de récupération du mot de passe et de suppression du compte, dont refus d'accès et reprise du nettoyage local.
- [x] Tests des états d'inscription, des dossards et de la confirmation HTTP de désinscription.
- [x] Tests de correction manuelle et d'échange HTTP des RPC de correction/publication.
- [x] Tests PostgreSQL embarqué de correction, publication, retrait de publication, unicité, révisions périmées, droits, rollback et compatibilité avec la suppression de compte.
- [x] Tests du rafraîchissement des résultats athlète : bouton, glissement, reprise, filtres conservés, erreur/réessai et retrait des résultats devenus non publiés.
- [x] Tests du programme : tri, disciplines/distances, statuts, lecture seule, champs d'affectation inconnus ou fournis, RPC et ouverture sans inscription/résultat.
- [x] Tests SQL du programme : périmètre de lecture, refus des brouillons/anonymes, absence d'écriture athlète et maintien des accès du coach propriétaire.

Bilan des derniers contrôles locaux : 94 tests Flutter réussis et analyse Flutter sans problème ; 29 tests serveur/SQL réussis lors du contrôle antérieur (non relancés pour cette configuration Android). Ces tests utilisent des faux dépôts, un serveur HTTP local et PGlite. Certaines protections SQL sont exercées sur un schéma de test ; les policies et migrations du projet Supabase déployé restent à vérifier. Aucun parcours de bout en bout sur appareils réels n'est validé par ce bilan.

### Parcours sur staging et appareils réels

- [ ] Préparer un coach propriétaire, un second coach et au moins deux comptes athlètes.
- [ ] Créer une compétition avec plusieurs épreuves et plusieurs manches.
- [ ] Tester la création de compte, confirmation d'e-mail, connexion, restauration de session et déconnexion.
- [ ] Tester la récupération du mot de passe et la suppression du compte après déploiement des fonctions et réglages serveur.
- [ ] Tester inscription, double inscription, désinscription et fermeture des inscriptions.
- [ ] Décider si une capacité maximale est nécessaire ; si oui, définir et tester le cas « compétition complète ».
- [ ] Tester l'ajout d'invités, les doublons de dossard et leur présence dans les résultats.
- [ ] Tester la configuration des épreuves, leur ordre, la réduction/augmentation des manches et la protection des résultats existants.
- [ ] Tester le départ d'une manche, le premier arrivé, le compte à rebours et les arrivées suivantes.
- [ ] Tester la limite exacte du délai, le passage hors délai et le démarrage automatique ou manuel de la suivante.
- [ ] Tester la dernière manche, les manches annulées et l'absence de manche suivante.
- [ ] Tester abandons, disqualifications, correction d'un temps et reclassement selon les fonctions réellement disponibles.
- [ ] Tester publication individuelle/groupée puis lecture par les athlètes inscrits.
- [ ] Tester l'actualisation des résultats athlète sur Général et Par manche, avec/sans filtre personnel, après correction, retrait de publication, republication et coupure réseau.
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
- [x] Fournir un workflow GitHub Actions d'analyse/tests Flutter et tests serveur ; son exécution distante reste à vérifier.

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
.\tool\build_android_release.ps1 -Environnement production -NumeroBuild 1
```

Le numéro de build est un exemple : utiliser le prochain numéro disponible dans la Console. Le bundle attendu est désormais `build/app/outputs/bundle/productionRelease/app-production-release.aab`. La Release exige identité confirmée, signature upload et `config/production.json` explicite ; analyse/tests ont été exécutés, le bundle signé reste à produire. Voir [android_release.md](../../docs/android_release.md).

## Android Release — bloquant avant Google Play

Préparation fournie : identité publique dans `android/application.properties`, signature upload sans repli debug, scripts de création de clé et de build, flavors production/staging et contrôles d'environnement. `com.example.triathlon` reste provisoire et bloque volontairement toute Release. La version reste `1.0.0+1` en attente de validation. Guide et limites : [android_release.md](../../docs/android_release.md).

- [ ] Choisir l'`applicationId` et le namespace définitifs, puis adapter les références Android nécessaires.
- [ ] Harmoniser le nom Android, le titre Flutter et le nom public de la fiche Store.
- [ ] Définir la version de lancement ; incrémenter le numéro de build à chaque nouvel envoi.
- [ ] Créer et configurer la clé d'upload et Play App Signing.
- [x] Remplacer la signature debug dans le bloc Release par une configuration upload ; faire échouer la livraison si elle manque.
- [ ] Conserver la clé et ses mots de passe dans un stockage sécurisé, avec sauvegarde et procédure d'accès.
- [x] Exclure les fichiers de signature et configurations locales, y compris PKCS12/DPAPI ; aucune clé de signature suivie ou trouvée dans l'historique Git accessible lors du contrôle.
- [ ] Maintenir ce contrôle avant chaque livraison et vérifier les autres secrets possibles.
- [ ] Vérifier le manifeste fusionné Release et ne conserver que les permissions justifiées.
- [x] Vérifier les appels print/debugPrint/log dans lib (aucun trouvé) et désactiver explicitement les logs Supabase en Release.
- [ ] Observer les logs du binaire Release final pendant les parcours et auditer les SDK ajoutés ultérieurement.
- [x] Fixer targetSdk=36 et vérifier le modèle Gradle local (compileSdk 36, targetSdk 36, minSdk 24).
- [ ] Confirmer ces valeurs dans le manifeste du bundle Release signé.
- [ ] Vérifier la compatibilité des dépendances et bibliothèques natives avec les exigences Android/Play applicables à la livraison.
- [ ] Tester la version Release sur appareils et via Google Play, pas uniquement en debug.
- [x] Prévoir des flavors et configurations staging/production ; contrôler le nom, APP_ENV, l'URL attendue et le type de clé au build et dans Flutter.
- [ ] Fournir le vrai projet staging, les configurations locales et réaliser la recette réseau/Auth de chaque environnement.
- [ ] Installer les Android SDK command-line tools manquants et vérifier les licences du SDK local.

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

1. Déployer et recetter les parcours existants de récupération du mot de passe et de suppression du compte ; terminer le parcours de confirmation d'e-mail.
2. Auditer réellement le schéma, les policies RLS et les droits des RPC sur staging.
3. Compléter les fonctions sportives et le détail athlète recensés plus haut.
4. Recetter les inscriptions, l'actualisation des résultats, les corrections transactionnelles et la concurrence avec une vraie base et plusieurs appareils.
5. Finaliser identité, signature Android et bundle Release.
6. Préparer confidentialité, déclarations Store et comptes de démonstration.
7. Passer par les pistes de test avant la production progressive.

Le cycle d'une manche, l'interface du premier arrivé, le compte à rebours, la publication et les classements de base sont déjà codés : leur recette reste nécessaire, mais ils ne sont plus à reconstruire depuis zéro.
