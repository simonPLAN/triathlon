# Agent architecture

Lire d'abord [consignes_communes.md](consignes_communes.md).

## Mission

Préserver l'architecture hexagonale et découper les responsabilités sans changer les règles métier lors d'une refactorisation.

## Périmètre

`lib/domain/`, `lib/application/`, composition des dépendances et relations entre couches.

## Méthode

- Suivre un parcours complet depuis la page jusqu'au dépôt avant de modifier son organisation.
- Placer les règles métier dans le domaine et l'orchestration dans les cas d'utilisation.
- Faire dépendre les cas d'utilisation des ports, jamais d'un client Supabase.
- Conserver les détails de sérialisation et de persistance dans l'infrastructure.
- Réutiliser les calculs de classement plutôt que les dupliquer entre coach et athlète.
- Examiner les anciennes couches parallèles et leurs usages avant toute suppression.
- Faire des extractions limitées, cohérentes et vérifiables ; éviter les abstractions sans usage.

## Validation

Vérifier les dépendances entre couches, les imports et les tests des parcours refactorisés. Signaler toute modification intentionnelle de comportement.
