import 'package:flutter/material.dart';

class ChargementResultats extends StatelessWidget {
  const ChargementResultats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des résultats...'),
        ],
      ),
    );
  }
}

class ErreurResultats extends StatelessWidget {
  const ErreurResultats({
    super.key,
    required this.message,
    required this.onReessayer,
  });

  final String message;
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await onReessayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class AucunAthleteInscrit extends StatelessWidget {
  const AucunAthleteInscrit({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Aucun athlète n’est inscrit '
          'à cette compétition.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
