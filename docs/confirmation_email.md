# Confirmation de l’adresse e-mail

## Comportement fourni

Après inscription sans session, l’application propose un écran dédié, affiche l’adresse saisie et permet de renvoyer le message. L’action est protégée pendant l’envoi, puis pendant 60 secondes. Un texte générique évite d’annoncer si une adresse existe.

Le lien Android utilise le flux PKCE avec le chemin `/confirm-email`. Il doit être ouvert sur l’installation qui a demandé le lien ; la réinstallation, un autre appareil ou le remplacement du vérificateur PKCE peut imposer une nouvelle demande. Les liens sans code, expirés et déjà utilisés affichent une erreur avec possibilité de renvoi.

Une session déjà ouverte est conservée : le lien n’est pas échangé automatiquement contre une autre session. Après un échange de confirmation réussi, la session temporaire est fermée localement et l’utilisateur revient à la connexion.

## Réglages Supabase à appliquer

Aucune modification de table n’est nécessaire pour cette fonctionnalité. Ces réglages ne sont pas déployés automatiquement :

1. Dans Authentication, activer Confirm email sur le projet de production.
2. Autoriser l’URL exacte `triathlon://auth/confirm-email` en production et `triathlon-staging://auth/confirm-email` dans le projet staging.
3. Vérifier que les modèles Confirm signup et renvoi utilisent le lien Supabase prévu, sans remplacer sa vérification par une URL arbitraire.
4. Configurer le SMTP, l’expiration des liens et les limites d’envoi.
5. Installer la nouvelle version Android pour prendre en compte le chemin ajouté au manifeste ; un hot reload ne suffit pas.

## Recette réelle restant à effectuer

- Inscrire une nouvelle adresse avec confirmation activée : aucun accès au compte avant validation.
- Ouvrir le vrai e-mail à chaud et à froid sur le téléphone qui a demandé le lien, puis se connecter.
- Renvoyer depuis l’application ; vérifier la limite locale, le délai serveur et les courriers indésirables.
- Tester un lien expiré, réutilisé, invalide et ouvert sur une autre installation.
- Avec une session existante, ouvrir le lien d’un autre compte : la session initiale doit être conservée.
- Tester la perte réseau à l’envoi et à l’échange.
- Vérifier aussi staging avec confirmation désactivée : une session directement renvoyée par Supabase est traitée comme telle, sans annoncer inutilement une confirmation obligatoire.

Les tests automatisés locaux couvrent validation d’adresse, routage, conservation d’une session, erreurs et double envoi. Ils ne prouvent pas la délivrabilité SMTP ni les réglages Supabase réels.
