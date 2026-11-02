# Récupération du mot de passe — Android / Supabase

Le bouton « Mot de passe oublié ? » ouvre la demande de lien. Le retour Android est traité au démarrage et pendant une session existante, au-dessus des autres pages. Le mot de passe est modifiable seulement après validation du code de récupération PKCE. Après succès ou annulation d'une récupération validée, la session de récupération est fermée localement ; l'utilisateur se reconnecte.

Un lien invalide ne donne pas accès au formulaire et ne déconnecte pas une session préexistante si aucun échange de code n'a eu lieu. Une panne réseau permet de réessayer l'enregistrement. Les doubles soumissions sont bloquées.

## Configuration à appliquer dans Supabase

Ces réglages serveur ne sont pas appliqués par le code Flutter.

Dans Authentication > URL Configuration > Redirect URLs :
- projet production : `triathlon://auth/reset-password`
- projet staging : `triathlon-staging://auth/reset-password`

Autoriser l'URL exacte, sans joker. Vérifier aussi la Site URL pour les retours web. Garder le lien `{{ .ConfirmationURL }}` dans le modèle Reset Password : il passe par la vérification Supabase avant le retour vers l'application. Configurer le SMTP et vérifier la délivrabilité et l'expiration des liens.

Le flux PKCE impose d'ouvrir le lien sur l'installation de l'application qui l'a demandé : l'ouverture sur un autre appareil, après réinstallation ou après remplacement du vérificateur par une nouvelle demande exige un nouveau lien. Ne jamais journaliser les liens/code/tokens.

Références officielles : [réinitialisation Dart](https://supabase.com/docs/reference/dart/auth-resetpasswordforemail), [liens mobiles Supabase](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter).

## Environnements

La production conserve par défaut le projet public existant. Pour sélectionner explicitement un projet :

```powershell
flutter run --dart-define=APP_ENV=staging --dart-define=SUPABASE_URL=https://PROJET_TEST.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=CLE_PUBLIQUE_TEST
flutter run --dart-define=APP_ENV=production --dart-define=SUPABASE_URL=https://PROJET_PROD.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=CLE_PUBLIQUE_PROD
```

Staging exige les deux paramètres Supabase ; aucune clé privilégiée/service_role dans les paramètres Flutter. Les deux filtres Android sont déclarés, mais seule l'URL de l'environnement courant est traitée. Ces variantes partagent actuellement l'applicationId : elles ne s'installent pas côte à côte.

Les URI personnalisées ne sont pas des liens HTTPS vérifiés. Si un domaine officiel est retenu, migrer vers Android App Links avec assetlinks.json et l'empreinte du certificat de signature. La réception des liens est configurée ici pour Android ; les autres plateformes nécessitent leur configuration native avant utilisation.

## Recette sur appareil — encore à effectuer

Installer à nouveau l'application après modification du manifeste : un hot reload ne suffit pas.

1. Sans session : demander un lien, vérifier le message générique et l'e-mail ; ouvrir le lien application au premier plan, puis refaire application arrêtée.
2. Saisir deux mots de passe différents, vérifier le refus ; enregistrer un mot de passe valide, revenir à la connexion et vérifier ancien mot de passe refusé / nouveau accepté.
3. Avec session coach ou athlète : ouvrir une page secondaire, demander un lien depuis une précédente demande (ou utiliser un compte test), ouvrir le lien et vérifier que le formulaire apparaît au-dessus de la navigation. Après validation, vérifier le retour à la connexion et l'absence d'accès aux pages précédentes.
4. Réutiliser le lien, attendre son expiration puis réessayer, tester un code invalide et un lien demandé depuis un autre appareil. Aucun formulaire de modification ne doit apparaître.
5. Simuler une perte réseau à l'envoi, à l'ouverture et à la sauvegarde ; vérifier le message et la reprise sans double envoi.
6. Annuler un lien invalide avec une session existante : vérifier qu'elle est conservée. Annuler une récupération valide : vérifier que sa session est fermée.
7. Refaire en staging et production avec leurs projets et URL autorisées respectifs.

Pour tester le routage Android et l'écran d'erreur sans un vrai e-mail :

```powershell
adb shell am start -a android.intent.action.VIEW -d "triathlon://auth/reset-password?error_code=otp_expired"
```

Les tests automatisés couvrent la validation, les doubles envois, les liens initiaux et reçus en session, les erreurs, le formulaire et la fermeture. Ils utilisent des dépôts simulés : ils ne prouvent pas la configuration serveur, le SMTP ou le fonctionnement du client e-mail sur appareil réel.
