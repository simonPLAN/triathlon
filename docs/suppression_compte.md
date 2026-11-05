# Suppression du compte et des données

## Parcours fourni

Dans les espaces athlète et coach, l'icône de compte « Supprimer mon compte » ouvre une page expliquant les conséquences. Il faut cocher la confirmation puis saisir le mot de passe actuel. La fonction Edge `supprimer-compte` vérifie la session via Auth.getUser et vérifie de nouveau le mot de passe avec un client isolé. Elle refuse tout identifiant fourni dans le corps de requête : la cible vient exclusivement du compte authentifié.

Aucune clé privilégiée n'est présente dans Flutter ou dans le site. La clé service_role est utilisée uniquement dans l'environnement serveur Supabase. Les comptes avec un second facteur vérifié sont refusés afin de ne pas contourner la MFA ; leur demande doit être traitée par le support après vérification d'identité. Le parcours actuel concerne les comptes e-mail/mot de passe de l'application.

Après confirmation serveur, Flutter ferme la session locale, retire explicitement la session persistée, vide les contrôleurs via AuthGate et revient à la connexion. Le répertoire d'athlètes est désormais également réinitialisé. Un échec du nettoyage local propose une reprise sans relancer la suppression serveur. Si une réponse réseau est perdue pendant la suppression, aucun succès n'est annoncé : vérifier le compte ou contacter le support.

## Traitement des données

| Données | Traitement | Quand |
|---|---|---|
| Compte Auth, identité et moyens de connexion | Hard delete par l'API Auth Admin ; sessions et identités gérées par Supabase Auth | Dans la transaction de suppression confirmée |
| Profil, prénom et nom du demandeur | Suppression de la ligne, pas de profil nominatif conservé | Même transaction |
| Inscriptions, dossards, résultats du demandeur | Suppression ciblée par athlete_id | Même transaction |
| Compétitions du coach | Responsable remplacé par un profil technique partagé sans compte Auth ; nom remplacé par « Compétition archivée », description et lieu effacés | Même transaction |
| Compétitions en brouillon, ouvertes ou en cours du coach | Annulation ; pas de suppression des épreuves/manches/participants | Même transaction |
| Épreuves, manches, inscriptions et résultats des AUTRES personnes | Conservés sans lien vers le compte supprimé comme responsable ; aucun recalcul des places/points historiques des autres | Selon la politique de conservation sportive à finaliser pour ces autres personnes |
| Profils invités | Conservés : ils représentent d'autres personnes. Leur propre demande doit être traitée séparément après vérification d'identité | Pas de suppression automatique avec le coach |
| Session de l'installation courante | Suppression mémoire, session persistée et vérificateur PKCE par le SDK | Après réponse serveur confirmée |
| Sauvegardes et journaux d'exploitation | Ne sont pas purgés par cette fonction | Dépendent de la rotation et des contrats réellement configurés |

Après installation de la migration 202611020005, supprimer un résultat publié retire également la publication de sa manche ; le coach doit vérifier/reclasser les résultats restants avant de republier. La suppression des résultats du demandeur peut laisser des trous dans les positions historiques ; les classements recalculés n'incluent plus ces résultats. Une compétition archivée reste consultable par les athlètes inscrits selon les policies existantes, mais n'a plus de responsable pouvant se connecter. Les noms d'épreuves et données des autres participants restent en place : ils ne sont pas déclarés anonymisés.

Aucune obligation légale de conservation n'est supposée par cette implémentation. Avant mise en ligne, le responsable du service doit valider et publier la politique de conservation des données sportives des autres personnes, des journaux et des sauvegardes. Il faut renseigner la durée réelle des sauvegardes dans `site/suppression-compte/configuration.js` (`retentionSauvegardesJours`), sans inventer un délai que l'infrastructure ne respecte pas. Une restauration de sauvegarde doit réappliquer les suppressions intervenues depuis sa date avant réouverture du service ; préparer cette procédure d'exploitation sans conserver un profil nominatif dans l'application.

## Protection transactionnelle

Appliquer `supabase/migrations/202611020004_suppression_compte.sql` après les trois migrations précédentes. Elle n'efface aucun compte à son installation.

L'Edge Function vérifie la présence de la protection SQL avant d'appeler Auth Admin deleteUser. Le trigger BEFORE DELETE sur auth.users :
1. Vérifie les relations entrantes vers profils, inscriptions, résultats et Auth hors schémas internes auth/storage.
2. Verrouille le profil et les compétitions concernées.
3. Transfère et neutralise les compétitions du coach.
4. Supprime uniquement les résultats, inscriptions et le profil du demandeur.
5. Laisse Auth supprimer le compte dans la même transaction.

Une erreur ou une relation non prévue annule tout. Le profil technique est unique, sans Auth, sans e-mail, sans possibilité de connexion et protégé des modifications client. Aucune fonction de nettoyage privilégiée n'est accordée à anon ou authenticated.

Le schéma initial du projet n'est pas entièrement versionné. Il faut impérativement vérifier le schéma et les triggers réels sur staging : références attendues profils.compte_id -> auth.users, competitions.coach_id -> profils, inscriptions.athlete_id -> profils et resultats.athlete_id -> profils. Une future table de pénalités, participants ou documents nécessite d'adapter et tester cette liste ; ne pas supprimer le contrôle pour contourner un refus.

L'application actuelle n'utilise pas Supabase Storage. Si des objets sont ajoutés, prévoir leur effacement via l'API Storage dans une stratégie adaptée avant la suppression Auth ; aucun DELETE direct sur storage.objects. Les JWT déjà émis peuvent rester valides jusqu'à expiration : tester les policies avec l'ancien token, les FK vers le profil/Auth supprimé et l'absence de possibilité de recréer un profil ou d'accéder aux données. La suppression Auth et la fermeture locale ne remplacent pas cet audit.

## Déploiement — restant à effectuer

1. Sur une base staging avec comptes jetables, appliquer la migration après sauvegarde et inspection du schéma.
2. Déployer la fonction :
   ```powershell
   supabase functions deploy supprimer-compte --project-ref REFERENCE_PROJET --no-verify-jwt
   ```
   `verify_jwt=false` dans config.toml désactive seulement le contrôle de la passerelle ; la fonction vérifie elle-même le bearer via Auth.getUser, notamment pour les clés de signature récentes. Les variables SUPABASE_URL, SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY sont fournies côté Edge Supabase. Ne jamais les copier dans Flutter sauf URL et clé publique.
3. Adapter `site/suppression-compte/configuration.js` : projet, clé publique, adresse de support, durée de sauvegardes vérifiée.
4. Héberger tout le dossier `site/suppression-compte/` en HTTPS sur le domaine officiel. Aucun serveur de formulaire supplémentaire : la page vérifie les identifiants et appelle la même fonction, sans stockage local des mots de passe ou tokens.
5. Appliquer les en-têtes HTTP fournis dans `_headers` si l'hébergeur les prend en charge, sinon les configurer dans son tableau de bord. Si un domaine Supabase personnalisé est utilisé, adapter aussi connect-src dans index.html.
6. Tester cette URL depuis un navigateur privé sans application installée. Vérifier le contact de support et le traitement des demandes MFA.
7. Renseigner l'URL publique finale dans Play Console > Sécurité des données > Suppression du compte ; utiliser l'identité publique définitive de l'application dans la page.
8. Refaire la recette sur un appareil et avec le schéma réel avant la release.

Le dépôt contient la page, mais aucun hébergement public ni réglage Play Console n'est réalisé ici. La configuration de contact et de conservation reste à compléter avant sa publication.

## Tests locaux

```powershell
flutter analyze
flutter test
deno check supabase/functions/supprimer-compte/index.ts
deno test supabase/functions/supprimer-compte/handler_test.ts
deno test --allow-read --allow-env --allow-sys supabase/tests/suppression_compte_test.ts
```

Les tests SQL exécutent la migration réelle dans PostgreSQL embarqué PGlite sur un schéma contractuel de test ; ils vérifient les cascades, la conservation des autres sportifs, l'atomicité, la réexécution et les droits des fonctions. Ils ne prouvent pas le comportement de la base actuellement déployée ni celui de l'API Auth réelle.

Recette staging à conserver :
- Athlète inscrit avec résultats ; autres sportifs et coach inchangés.
- Coach avec invité, athlètes, plusieurs épreuves/manches ; transfert, annulation et lecture des autres participants.
- Mot de passe faux, session absente/expirée, identifiant d'une autre personne injecté.
- MFA activée, double clic, perte réseau avant/après réponse, échec du stockage local.
- Ancien refresh token refusé, tentative avec ancien JWT, reconnexion impossible après suppression.
- Page web privée, sans application ; succès réel jusqu'à disparition Auth et données.
- Relation FK ajoutée et erreur SQL : aucun effacement partiel.
- Vérification des triggers existants, absence de fuite dans logs et sauvegardes restaurées.

Références officielles : [suppression Auth côté serveur](https://supabase.com/docs/reference/javascript/auth-admin-deleteuser), [sécurisation des fonctions](https://supabase.com/docs/guides/functions/auth), [exigences Google Play](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).
