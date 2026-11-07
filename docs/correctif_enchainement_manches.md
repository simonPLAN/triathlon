# Correctif d'enchaînement automatique des manches

Exécuter `supabase/migrations/202611050008_enchainement_manches.sql` après les
migrations sportives précédentes.

Lorsque l'option d'enchaînement est active :

- la prochaine manche à venir de la même épreuve est recherchée ;
- si elle n'a pas encore de participants, elle reprend les participants,
  l'ordre de départ et le délai de la manche terminée ;
- elle démarre dans la même transaction que la clôture du délai ;
- une manche déjà configurée conserve sa propre sélection.

Le client applique la même règle lors d'une terminaison manuelle. S'il existe
une manche suivante mais qu'elle ne peut pas être configurée ou démarrée,
l'erreur est désormais affichée au coach au lieu d'un échec silencieux.
