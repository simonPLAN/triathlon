# Migration vers les pseudos

## Objectif

La connexion reste basée sur l'adresse e-mail et le mot de passe Supabase Auth.
Le profil sportif public ne collecte plus de prénom ni de nom : seul un pseudo
unique est demandé et affiché.

## Application

1. Sauvegarder la base et tester d'abord sur l'environnement staging.
2. Exécuter entièrement
   `supabase/migrations/202611050002_profils_pseudo.sql` dans le SQL Editor.
3. Relancer l'application, puis effectuer un hot restart.
4. Créer un nouveau compte et un invité, puis vérifier inscriptions, résultats
   et classements avec deux comptes différents.

Les anciens profils reçoivent volontairement un pseudo neutre
`athlete_<identifiant>`. Les anciens noms et prénoms ne sont pas réutilisés :
leurs valeurs sont remplacées. L'utilisateur pourra choisir un nouveau pseudo
lorsqu'un écran de modification de profil sera ajouté.

Les colonnes SQL historiques `prenom` et `nom` restent provisoirement pour
la compatibilité des fonctions déjà déployées, mais ne contiennent plus
d'identité civile. Elles sont alimentées avec le pseudo et une chaîne vide.

## Retour arrière

Ne pas tenter de reconstruire les noms à partir des pseudos. Restaurer la
sauvegarde réalisée avant migration si un retour complet est nécessaire.
