import 'package:flutter/material.dart';

import '../../../domain/entities/manche.dart';

class ActionsManche extends StatelessWidget {
  const ActionsManche({
    super.key,
    required this.manche,
    required this.actionEnCours,
    required this.onDemarrer,
    required this.onPremiereArrivee,
    required this.onTerminer,
    required this.onAnnuler,
    required this.onPublierResultats,
  });

  final Manche manche;
  final bool actionEnCours;

  final Future<void> Function() onDemarrer;
  final Future<void> Function() onPremiereArrivee;
  final Future<void> Function() onTerminer;
  final Future<void> Function() onAnnuler;
  final Future<void> Function() onPublierResultats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (manche.estAVenir)
              FilledButton.icon(
                onPressed: actionEnCours
                    ? null
                    : () async {
                        await onDemarrer();
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Démarrer la manche'),
              ),
            if (manche.estEnCours && !manche.premierArrive)
              FilledButton.icon(
                onPressed: actionEnCours
                    ? null
                    : () async {
                        await onPremiereArrivee();
                      },
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Enregistrer le premier arrivé'),
              ),
            if (manche.estEnCours) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: actionEnCours
                    ? null
                    : () async {
                        await onTerminer();
                      },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Terminer la manche'),
              ),
            ],
            if (manche.peutPublierResultats)
              FilledButton.icon(
                onPressed: actionEnCours
                    ? null
                    : () async {
                        await onPublierResultats();
                      },
                icon: const Icon(Icons.publish_outlined),
                label: const Text('Publier les résultats'),
              ),
            if (!manche.estTerminee && !manche.estAnnulee) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: actionEnCours
                    ? null
                    : () async {
                        await onAnnuler();
                      },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Annuler la manche'),
              ),
            ],
            if (actionEnCours) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
