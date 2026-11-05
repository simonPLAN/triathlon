import 'package:flutter/material.dart';

class ActionsConfigurationEpreuve extends StatelessWidget {
  const ActionsConfigurationEpreuve({
    super.key,
    required this.actives,
    required this.peutMonter,
    required this.peutDescendre,
    required this.onMonter,
    required this.onDescendre,
    required this.onModifier,
    required this.onSupprimer,
  });
  final bool actives;
  final bool peutMonter;
  final bool peutDescendre;
  final VoidCallback onMonter;
  final VoidCallback onDescendre;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton(
        tooltip: 'Monter l’épreuve',
        onPressed: actives && peutMonter ? onMonter : null,
        icon: const Icon(Icons.arrow_upward),
      ),
      IconButton(
        tooltip: 'Descendre l’épreuve',
        onPressed: actives && peutDescendre ? onDescendre : null,
        icon: const Icon(Icons.arrow_downward),
      ),
      TextButton.icon(
        onPressed: actives ? onModifier : null,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Modifier'),
      ),
      TextButton.icon(
        onPressed: actives ? onSupprimer : null,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Supprimer'),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    ],
  );
}
