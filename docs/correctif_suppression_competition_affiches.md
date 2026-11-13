# Correctif de suppression d'une compétition avec affiches

## Problème

La suppression d'une compétition brouillon échouait lorsqu'une de ses épreuves
possédait une affiche. La contrainte `affiches_epreuve_epreuve_id_fkey`
interdisait la suppression de l'épreuve référencée.

## Installation

Exécuter dans l'éditeur SQL Supabase :

`supabase/migrations/202611130008_suppression_competition_affiches.sql`

La migration remplace uniquement cette clé étrangère par une suppression en
cascade. Supprimer une compétition supprimera donc les métadonnées des affiches
de ses propres épreuves, sans toucher aux autres compétitions.

Les fichiers Storage orphelins peuvent ensuite être identifiés avec la fonction
`lister_objets_affiches_orphelins` déjà fournie par la gestion des affiches.
