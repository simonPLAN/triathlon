# Groupes d'athlètes

## Installation Supabase

1. Sauvegarder la base et tester sur l'environnement staging.
2. Exécuter entièrement
   `supabase/migrations/202611050007_groupes_athletes.sql`.
3. Effectuer un hot restart de l'application.
4. Avec un compte coach, ouvrir **Athlètes**, puis l'icône **Groupes**.
5. Créer un groupe et sélectionner ses membres.
6. Ouvrir une manche à venir, choisir **Configurer les participants**, puis
   sélectionner le groupe.

## Règles

- Chaque groupe appartient au coach connecté.
- Deux groupes du même coach ne peuvent pas porter le même nom.
- Un athlète réel visible dans l'annuaire peut être ajouté.
- Un invité ne peut être ajouté que par le coach qui l'a inscrit.
- Dans une manche, seuls les membres déjà inscrits à la compétition sont
  sélectionnés.
- La suppression d'un groupe ne supprime jamais les athlètes, inscriptions ou
  résultats.
- Les tables sont en RLS ; les écritures passent par des fonctions contrôlées.

## Vérifications recommandées

Tester avec deux coachs, un athlète réel et un invité afin de confirmer qu'un
coach ne peut ni lire ni modifier les groupes de l'autre.
