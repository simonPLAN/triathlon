# Livraison Android

## État et décisions attendues

La configuration prépare deux variantes : `production` et `staging` (identifiant suffixé `.staging`, libellé « (test) » et lien de récupération distinct). Elles peuvent être installées côte à côte. Le debug conserve le projet public existant ; une Release exige une configuration explicite et refuse une identité provisoire, une signature absente ou un projet Supabase incorrect.

Il reste à confirmer le nom public, l'identifiant Android définitif, la version initiale et l'existence d'une ancienne clé d'upload. Ne pas recréer une clé si une application est déjà distribuée. Aucune clé de production n'a été créée et Play App Signing n'a pas été activé depuis ce dépôt.

Dans `android/application.properties`, renseigner `applicationId`, `namespace`, `appName`, puis `identityConfirmed=true` après validation. Le fichier est public. Adapter aussi le `package` et l'emplacement de `android/app/src/main/kotlin/com/example/triathlon/MainActivity.kt` au namespace choisi : le manifeste utilise `.MainActivity`. Ne jamais changer l'applicationId d'une application déjà publiée.

Le titre Flutter vient de `APP_NAME` et doit correspondre au libellé Android ; les builds Release vérifient cette correspondance. Reprendre exactement ce nom dans la fiche Google Play et les pages publiques. Les valeurs `com.example.triathlon` et « Triathlon » restent provisoires.

## Environnements

Copier les exemples `config/production.example.json` et `config/staging.example.json` vers `config/production.json` et `config/staging.json` (ignorés par Git). Renseigner une URL et une clé **publique** publishable ou anon, jamais une clé secrète/service_role. Les paramètres compilés dans Flutter restent extractibles : ce ne sont pas des secrets et ils ne remplacent pas RLS.

La production est actuellement liée à `dgjtfhslcbrgsdczlvdg.supabase.co`. Staging doit utiliser un autre projet. Si le projet de production change, mettre à jour ensemble `productionSupabaseHost` dans `android/application.properties`, `ConfigurationAuthentification.hoteProduction` dans Dart et les configurations locales. APP_ENV doit correspondre au flavor ; APP_NAME vaut le nom public, suffixé « (test) » pour staging.

```powershell
flutter run --flavor production
flutter run --flavor staging --dart-define-from-file=config/staging.json
```

Les redirections Supabase restent à configurer et à tester : [récupération du mot de passe](recuperation_mot_de_passe.md). Le flavor production est celui par défaut. Une Release sans fichiers explicites échoue au lieu de reprendre la configuration de debug.

## Clé d'upload et accès

Pour une nouvelle application uniquement, après confirmation de son identifiant :

```powershell
.\tool\creer_cle_upload.ps1 -ApplicationId fr.organisation.application
```

Le script refuse l'identifiant exemple et tout écrasement. Il crée une clé RSA 4096/PKCS12, alias `upload`, hors dépôt dans `%USERPROFILE%\.triathlon\signature\<applicationId>`, avec accès limité au compte Windows et SYSTEM. Le mot de passe aléatoire n'est pas affiché : sa copie locale est protégée par Windows DPAPI dans `upload-password.clixml` et sert au script de build.

**La copie DPAPI est liée au compte Windows et à sa machine ; elle ne constitue pas une sauvegarde portable.** Avant toute publication, sauvegarder le keystore et le mot de passe dans un coffre chiffré avec accès restreint ; prévoir une seconde sauvegarde et tester sa restauration sur une machine distincte. Pour déplacer le mot de passe vers le coffre, utiliser une procédure locale confidentielle sans le coller dans un terminal partagé, un ticket ou Git. Documenter les personnes habilitées et la procédure de départ/remplacement. Ne pas considérer cette étape réalisée simplement parce que le script existe.

Pour une clé existante ou une CI, injecter `TRIATHLON_STORE_FILE`, `TRIATHLON_STORE_PASSWORD`, `TRIATHLON_KEY_ALIAS`, `TRIATHLON_KEY_PASSWORD` depuis le coffre. Alternative locale : copier `android/key.properties.example` vers `android/key.properties` et compléter hors Git. Préférer des chemins absolus avec `/`. Aucun repli vers la clé debug n'existe en Release.

`key.properties`, `.jks`, `.keystore`, `.p12`, `.pfx`, `.clixml` et les configurations locales sont ignorés. La recherche Git des fichiers de signature suivis et dans l'historique accessible n'en a trouvé aucun ; cela ne prouve pas l'absence de tous les secrets possibles.

Dans la Play Console, activer **Play App Signing** lors de la première livraison. La clé ci-dessus signe l'upload ; Google signe les APK distribués avec sa clé de signature d'application. Conserver les empreintes des deux certificats et utiliser celle de signature Google pour les futurs Android App Links. Ces réglages Console ne sont pas automatisés ici.

## Version et build

`pubspec.yaml` conserve `1.0.0+1` en attente de validation de la version de lancement. Le nom de version est transmis à Gradle ; le script impose un numéro de build explicite. Chaque nouvel envoi à Google Play doit utiliser un numéro supérieur au dernier déjà téléversé, y compris après un essai abandonné. Vérifier cette valeur dans la Console avant le build ; le dépôt ne connaît pas son historique.

Depuis la racine, après configuration de l'identité, de l'environnement et de la signature :

```powershell
flutter pub get
flutter analyze
flutter test
.\tool\build_android_release.ps1 -Environnement production -NumeroBuild 1
```

Adapter `NumeroBuild` au prochain numéro disponible. Le script lit les identifiants de signature du coffre Windows local ou des variables existantes, puis les retire de son environnement après le build. En CI, les injecter depuis le gestionnaire de secrets.

Commande Flutter équivalente si la signature est déjà fournie :

```powershell
flutter build appbundle --release --flavor production --build-number=1 --dart-define-from-file=config/production.json
```

Artefact attendu : `build/app/outputs/bundle/productionRelease/app-production-release.aab`. Pour staging : `stagingRelease/app-staging-release.aab`. Ne pas déposer un bundle staging dans l'application de production.

## Contrôles du binaire final

Le modèle Gradle local résout compileSdk 36, targetSdk 36, minSdk 24 et NDK 28.2.13676358 avec Flutter 3.47.7. La cible API 36 est explicite. AGP 9.1.0 et Gradle 9.3.1 sont conservés. Le SDK local manque actuellement de command-line tools ; les installer depuis SDK Manager et accepter les licences avant la livraison.

Le manifeste source conserve INTERNET, refuse le trafic HTTP et désactive la sauvegarde Android. MainActivity reste exportée pour le lanceur et le lien de récupération ; chaque variante ne déclare que son schéma. Aucun appel print/debugPrint/log n'a été trouvé dans lib lors de cette revue et les logs internes Supabase sont désactivés en Release.

Ces constats ne remplacent pas l'analyse du **bundle signé final** :

- Ouvrir le manifeste fusionné de la variante productionRelease dans Android Studio. Relever toutes les permissions injectées par les dépendances et justifier chacune ; vérifier debuggable=false, applicationId, versionCode, versionName, targetSdk=36, composants exportés et absence des filtres réseau de debug. PROCESS_TEXT sert à la sélection de texte.
- Valider l'AAB avec la version officielle de bundletool (`java -jar bundletool-all.jar validate --bundle=...`) et sa signature avec `jarsigner -verify -verbose -certs ...`. Comparer l'empreinte du certificat à celle de la clé d'upload prévue.
- Examiner l'AAB avec APK Analyzer ; contrôler les bibliothèques natives pour chaque ABI et les dépendances transitives. La version de NDK seule ne garantit pas l'alignement des bibliothèques précompilées.
- Vérifier le support des pages mémoire 16 Ko : configuration bundletool, alignement ZIP des APK issus du bundle (`zipalign -c -P 16 -v 4 ...`) et alignement des segments ELF LOAD de chaque `.so` avec llvm-readelf. Tester les APK sur un appareil/émulateur en pages 16 Ko. Un APK qui démarre sur un téléphone en pages 4 Ko ne suffit pas.
- Installer via une piste interne Play et vérifier les rapports pré-lancement, le démarrage sans outils de debug, la navigation, Auth/PKCE avec et sans session, les accès Supabase, la suppression du compte et les opérations sportives, puis la reprise après coupure réseau.
- Observer les journaux de cette Release pendant les parcours ; aucun lien de récupération, JWT, mot de passe, identité ou résultat personnel ne doit être journalisé. Vérifier aussi les SDK ajoutés ultérieurement.

Contrôles de cette préparation : analyse Flutter sans problème, 94 tests Flutter réussis, compilation des APK debug production et staging réussie, syntaxe des deux scripts PowerShell validée. Le contrôle Gradle Release refuse bien l'identité provisoire. Le build staging utilise des paramètres fictifs uniquement pour compiler : il ne valide aucun accès réseau.

Aucun AAB de production, contrôle natif de ce binaire, installation Release sur appareil ni test Play n'est validé à ce stade. L'identité et la clé restent à fournir ; aucun appareil Android n'est connecté pendant cette préparation.

Références officielles : [livraison Flutter](https://docs.flutter.dev/deployment/android), [flavors Flutter](https://docs.flutter.dev/deployment/flavors), [niveau d'API Google Play](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [pages mémoire 16 Ko](https://developer.android.com/guide/practices/page-sizes). Revérifier les exigences dans la Play Console au moment du dépôt.
