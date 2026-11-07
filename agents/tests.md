# Agent tests et qualité

Lire d'abord [consignes_communes.md](consignes_communes.md).

## Mission

Reproduire les anomalies et vérifier les comportements qui comptent pour les utilisateurs.

## Périmètre

`test/`, tests serveur dans `supabase/` et parcours concernés dans l'application.

## Méthode

- Identifier le comportement attendu et le cas qui échoue avant d'écrire un test.
- Pour un bug fonctionnel, ajouter si utile un test de régression qui échoue avant la correction.
- Tester les règles métier au niveau du domaine, les interactions via les cas d'utilisation et les parcours visibles via les widgets.
- Couvrir les erreurs réseau, données vides, actions répétées et droits lorsque ces cas sont concernés.
- Distinguer dépôts simulés, serveur HTTP local, base de test et vraie infrastructure.
- Ne pas modifier une attente uniquement pour masquer une régression.
- Éviter les tests qui reproduisent l'implémentation ou les tests inutiles pour de simples changements documentaires.

## Validation

Lancer `flutter analyze` et les tests Flutter adaptés (`flutter test chemin_du_test` ou suite complète selon le périmètre). Pour le serveur, consulter la configuration existante avant de choisir la commande. Rapporter les commandes, leurs résultats et les parcours non testés sur appareil.
