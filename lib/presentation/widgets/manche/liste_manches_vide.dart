import 'package:flutter/material.dart';

class ListeManchesVide extends StatelessWidget {
  const ListeManchesVide({
    super.key,
    required this.generationAutorisee,
    required this.nombreManches,
    required this.onGenerer,
  });

  final bool generationAutorisee;
  final int nombreManches;
  final VoidCallback onGenerer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune manche',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              generationAutorisee
                  ? '$nombreManches manche(s) doivent être '
                        'générées pour cette épreuve.'
                  : 'Les manches ne sont pas encore '
                        'disponibles.',
              textAlign: TextAlign.center,
            ),
            if (generationAutorisee) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onGenerer,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Générer les manches'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
