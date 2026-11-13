# Image de couverture des compétitions

La migration `supabase/migrations/202611130002_image_competition.sql` ajoute une
image de couverture facultative par compétition.

## Comportement

- formats : JPEG, PNG et WebP ;
- limite : 5 Mio et 4096 × 4096 pixels ;
- bucket privé `images-competitions` ;
- modification réservée au coach responsable tant que la compétition est en
  brouillon ;
- lecture réservée aux utilisateurs authentifiés autorisés à consulter la
  compétition ;
- affichage dans les cartes coach et athlète ;
- remplacement atomique : le nouvel objet est finalisé avant le nettoyage de
  l'ancien.

## Application

1. Sauvegarder la base et utiliser d'abord le projet Supabase staging.
2. Appliquer auparavant `202611130001_affiches_epreuves.sql`.
3. Exécuter `202611130002_image_competition.sql` dans le SQL Editor.
4. Exécuter ensuite
   `202611130003_correctif_image_competition_storage.sql`.
5. Si l’envoi renvoie encore un statut Storage 403, exécuter
   `202611130004_correctif_autorisation_image_competition.sql`. Ce correctif
   vérifie directement le coach propriétaire et le statut brouillon.
6. Vérifier que le bucket `images-competitions` est privé.
7. Tester avec un coach propriétaire, un autre coach, un athlète inscrit et une
   session absente.
8. Appliquer en production uniquement après la recette staging.

La migration n'est pas exécutée automatiquement par l'application.

## Vérifications attendues

- création d'une compétition sans image ;
- création avec image puis affichage dans « Mes compétitions » ;
- affichage sur l'accueil athlète après ouverture des inscriptions ;
- remplacement et suppression pendant le brouillon ;
- refus de modification après ouverture ;
- refus des formats, tailles et dimensions non autorisés ;
- absence d'accès anonyme au fichier ;
- conservation de l'ancienne image si le remplacement échoue.

## État

- Migration locale : préparée, non déployée.
- Analyse Flutter : réussie.
- Tests Flutter : 133 réussis.
- Recette Supabase staging : à effectuer.
