# Le Mans Triathlon Series — version web

## GitHub Pages

Adresse prévue : https://simonplan.github.io/triathlon/

1. Committer puis pousser les modifications, dont `.github/workflows/pages.yml`,
   sur `main` ou `master`.
2. Dans GitHub → Settings → Pages, sélectionner **GitHub Actions** comme source.
3. Dans Actions, lancer **Publier le site LMTS** si nécessaire.
4. Attendre que les étapes build et deploy deviennent vertes.

Dans Supabase → Authentication → URL Configuration, autoriser aussi :
- https://simonplan.github.io/triathlon/auth/reset-password
- https://simonplan.github.io/triathlon/auth/reset-password/
- https://simonplan.github.io/triathlon/confirm-email
- https://simonplan.github.io/triathlon/confirm-email/

Les URL avec et sans barre finale couvrent la normalisation des dossiers par
GitHub Pages. La comparaison des liens Auth doit accepter ces deux formes.

Dans Settings → Secrets and variables → Actions → Variables, renseigner
`PRIVACY_POLICY_URL`, `ACCOUNT_DELETION_URL` et `SUPPORT_EMAIL` avec les valeurs
publiques de production. Les clés privilégiées et la signature Android ne sont
jamais nécessaires pour cette publication.

La préparation locale ne publie rien à distance ; le lien sera disponible
après le déploiement GitHub Actions.

Cette version utilise les mêmes écrans Flutter, cas d'utilisation et dépôts
Supabase que l'application Android. Les espaces coach et athlète sont déterminés
par le rôle du compte connecté.

## Lancer en local

Depuis la racine du projet :

```powershell
flutter run -d chrome --web-port 8080 --dart-define-from-file=config/production.json
```

Cette configuration utilise la base de production. Pour des essais isolés,
utiliser une configuration staging et son projet Supabase.

## Générer les fichiers à héberger

```powershell
flutter build web --release --dart-define-from-file=config/production.json
```

Déployer le contenu de `build/web` sur un hébergement HTTPS. Le dossier
`web` contient les sources du démarrage navigateur ; il ne faut pas ouvrir
`index.html` directement depuis le disque.

Configurer l'hébergement pour renvoyer les routes inconnues vers `index.html`
(réécriture SPA), notamment les chemins Auth ci-dessous. Ne pas réécrire les
ressources statiques existantes.

## Supabase Auth

Dans Authentication → URL Configuration, autoriser les redirections :

- `http://localhost:8080/auth/reset-password`
- `http://localhost:8080/confirm-email`
- `https://VOTRE_DOMAINE/auth/reset-password`
- `https://VOTRE_DOMAINE/confirm-email`

Remplacer VOTRE_DOMAINE par le domaine choisi. Conserver les redirections
Android déjà utilisées. Les liens de récupération et de confirmation doivent
être ouverts dans le navigateur qui a demandé le lien (flux PKCE).

Les règles RLS et les migrations sont communes aux deux versions ; aucune
nouvelle table n'est nécessaire pour le web.

## Recette

Vérifier dans Chrome et sur mobile : connexion et restauration de session,
création de compte, confirmation, récupération, groupes, inscriptions,
configuration des manches, arrivées, publication, lecture des résultats,
graphiques, déconnexion et suppression du compte.

La compilation seule ne valide pas ces parcours sur la base distante.
