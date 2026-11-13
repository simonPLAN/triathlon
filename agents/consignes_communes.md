# Consignes communes

## Contexte à consulter

- `lib/ia/info.md` : description et architecture du projet.
- `lib/ia/raf.md` : reste à faire et vérifications encore attendues.
- Le code, ses usages et les tests concernés : ils permettent de vérifier les affirmations de la
  documentation.

Triathlon est une application Flutter/Dart avec Supabase. Les parcours coach et athlète ont des
droits différents.

## Manière de travailler

- Comprendre la demande et examiner l'existant avant toute modification. Pour une demande de
  conseil, rester en discussion.
- Respecter les changements non committés et les fichiers ouverts. Utiliser les outils de l'IDE
  lorsqu'ils sont disponibles, en tenant compte des buffers non enregistrés.
- Limiter les modifications au périmètre demandé ; éviter les refontes annexes et les dépendances
  inutiles.
- Respecter les noms et conventions français du projet.
- Consulter les usages avant de déplacer ou supprimer un symbole. Préserver les parcours existants.
- Ne pas lancer d'autres agents sans demande explicite de l'utilisateur. Pour le profil
  `agent-developeur.md`, l'utilisateur a demandé la consultation de `agent-interface.md` pendant les
  tâches d'implémentation : cette collaboration est autorisée lors de l'activation du profil, dans
  les limites de la tâche et des outils disponibles. Elle ne lance pas automatiquement de processus
  à l'ouverture des fichiers.
- Ne pas publier, déployer ou modifier les services distants sans que la demande couvre cette
  action.

## Architecture

- `lib/domain/` contient les entités, ports et services métier ; il ne dépend ni de Flutter ni de
  Supabase.
- `lib/application/use_cases/` orchestre les règles via les ports.
- `lib/infrastructure/` implémente les accès techniques et les conversions.
- `lib/presentation/` contient pages, widgets et contrôleurs.
- Garder les classes centrées sur une responsabilité ; extraire selon les responsabilités plutôt que
  selon une limite arbitraire de lignes.
- Les anciens fichiers parallèles existent encore : vérifier leurs usages avant de les migrer.

## Vérification et compte rendu

- Choisir des vérifications proportionnées au changement. Pour le code Dart, formater les fichiers
  modifiés, lancer l'analyse et les tests pertinents.
- Ne jamais annoncer un test réussi sans l'avoir exécuté. Une migration écrite n'est pas une
  migration déployée.
- Mettre à jour le RAF si une fonctionnalité ou une vérification y change réellement d'état.
- Terminer par les changements, les contrôles effectués et les points encore à vérifier.
- Ne jamais écrire de mots de passe, clés privilégiées, tokens ou clés de signature dans les
  consignes ou les comptes rendus.
