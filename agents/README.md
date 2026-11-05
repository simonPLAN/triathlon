# Agents du projet Triathlon

Ce dossier contient des consignes réutilisables pour les assistants IA qui travaillent sur le projet
Flutter/Supabase. Il ne contient aucun service exécutable et ne lance pas automatiquement d'agents.

## Utilisation

1. Choisir un profil dans le tableau ci-dessous.
2. Demander à l'assistant de lire `agents/consignes_communes.md`, puis le profil choisi.
3. Donner une tâche précise, son périmètre et le résultat attendu.

Exemple de demande à copier dans la conversation de l'assistant :

> Utilise agents/developeur.md pour améliorer la page de détail d'une compétition côté athlète.
> Consulte agents/agent-interface.md comme prévu dans le profil, préserve les règles métier et
> vérifie les parcours modifiés.

Les outils de l'assistant déterminent comment charger ces fichiers. Leur présence seule ne garantit
pas leur chargement automatique.

## Profils

| Fichier                                  | Rôle                                                                |
|------------------------------------------|---------------------------------------------------------------------|
| [developeur.md](developeur.md) | Développeur Android/Flutter, coordonne l'agent interface |
| [agent-interface.md](agent-interface.md) | Cohérence visuelle, accessibilité et expérience utilisateur |
| [architecture.md](architecture.md)       | Découper les responsabilités et préserver l'architecture hexagonale |
| [flutter.md](flutter.md)                 | Construire les écrans, widgets et contrôleurs                       |
| [supabase.md](supabase.md)               | Dépôts, migrations, autorisations et traitements serveur            |
| [tests.md](tests.md)                     | Reproduire les anomalies et vérifier les comportements              |
| [android_release.md](android_release.md) | Préparer les APK, AAB, environnements et signatures                 |

[Consignes communes](consignes_communes.md) : à lire avec chaque profil.

## Ajouter un agent

Créer un fichier Markdown décrivant la mission, le périmètre, la méthode et les validations de l'agent,
puis ajouter son lien au tableau. Garder chaque profil centré sur une responsabilité ; les règles
partagées restent dans les consignes communes.

Le profil développeur prévoit la consultation de l'agent interface avant implémentation et une
revue des changements visibles après implémentation. L'utilisateur a demandé cette collaboration.
Si l'outil permet les sous-agents, le développeur peut lui déléguer la revue ; sinon, le même
assistant applique les deux profils et le signale. Les fichiers seuls ne démarrent aucun agent.
Pour d'autres collaborations, demander explicitement leur utilisation et répartir les fichiers
avant les modifications.
