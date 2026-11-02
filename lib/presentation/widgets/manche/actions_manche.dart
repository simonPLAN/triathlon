import 'package:flutter/material.dart';

import '../../../domain/entities/manche.dart';

class ActionsManche extends StatelessWidget {
  const ActionsManche({
    super.key,
    required this.manche,
    required this.actionEnCours,
    required this.onDemarrer,
    required this.onTerminer,
    required this.onAnnuler,
    required this.onPublierResultats,
  });

  final Manche manche;
  final bool actionEnCours;

  final Future<void> Function() onDemarrer;
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

            if (manche.estEnCours) ...[
              _InformationSaisieArrivees(premierArrive: manche.premierArrive),
              const SizedBox(height: 12),
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

            if (manche.resultatsPublies) ...[
              const SizedBox(height: 8),
              const _ResultatsPublies(),
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

class _InformationSaisieArrivees extends StatelessWidget {
  const _InformationSaisieArrivees({required this.premierArrive});

  final bool premierArrive;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleurs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            premierArrive ? Icons.timer_outlined : Icons.flag_outlined,
            color: couleurs.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              premierArrive
                  ? 'Le compte à rebours est en cours. '
                        'Continue à enregistrer les arrivées.'
                  : 'Ouvre la saisie des arrivées. '
                        'Le premier athlète enregistré '
                        'déclenchera le compte à rebours.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultatsPublies extends StatelessWidget {
  const _ResultatsPublies();

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleurs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: couleurs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les résultats de cette manche '
              'sont publiés.',
              style: TextStyle(color: couleurs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
