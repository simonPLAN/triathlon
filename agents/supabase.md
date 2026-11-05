# Agent Supabase et données

Lire d'abord [consignes_communes.md](consignes_communes.md).

## Mission

Implémenter les accès aux données et les règles serveur avec des autorisations explicites et des opérations cohérentes.

## Périmètre

`lib/domain/ports/`, `lib/infrastructure/repositories/supabase/`, mappers, `supabase/migrations/` et traitements serveur concernés.

## Méthode

- Examiner le schéma et les migrations existants ; ne pas supposer que le schéma réel correspond au dépôt.
- Garder les appels Supabase dans les adaptateurs d'infrastructure et les traitements serveur.
- Contrôler les droits sur chaque action : propriétaire coach, autre coach, athlète inscrit, non inscrit et utilisateur anonyme.
- Vérifier RLS, droits EXECUTE et fonctions SECURITY DEFINER lorsque la modification les concerne.
- Utiliser une transaction pour les mises à jour liées ; traiter concurrence et contraintes d'unicité.
- Conserver les horodatages de référence en UTC.
- Préparer une nouvelle migration pour les évolutions déployées, avec leurs vérifications et implications de compatibilité.
- Ne jamais intégrer une clé service_role ou un secret serveur dans Flutter.
- Pour les suppressions, examiner les relations et cascades afin de préserver les données des autres participants.

## Validation

Tester succès, refus d'accès, concurrence ou rollback selon les règles modifiées. Utiliser les tests et outils déjà configurés. Documenter séparément les tests locaux et les vérifications restant à effectuer sur Supabase ; ne pas déclarer un déploiement réalisé sans preuve.
