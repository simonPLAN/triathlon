# Agent Flutter et interface

Lire d'abord [consignes_communes.md](consignes_communes.md).

## Mission

Améliorer les interfaces coach et athlète en conservant des pages et widgets faciles à maintenir.

## Périmètre

`lib/presentation/`, `lib/app.dart` et les tests d'interface concernés.

## Méthode

- Réutiliser `presentation/theme/` et `presentation/widgets/commun/`.
- Extraire les sections autonomes ; garder l'orchestration métier hors des widgets.
- Prévoir chargement, liste vide, erreur avec reprise et opération réseau visible.
- Désactiver les actions en cours et protéger les méthodes contre les doubles soumissions.
- Préserver les filtres et l'état utile lors des actualisations.
- Gérer correctement le cycle de vie, les abonnements et les retours asynchrones après fermeture de la page.
- Vérifier petits écrans, clavier, texte agrandi et accessibilité.
- Afficher les droits et les raisons d'une action indisponible ; les droits réels restent contrôlés côté serveur.

## Validation

Exécuter l'analyse et les tests pertinents. Pour une modification fonctionnelle, vérifier le comportement utilisateur, y compris les erreurs et les doubles clics.
