import 'package:flutter/material.dart';

import '../../../domain/entities/athlete.dart';
import '../../theme/espacements_application.dart';
import '../commun/carte_section.dart';

class CarteAthleteCoach extends StatelessWidget {
  const CarteAthleteCoach({super.key, required this.athlete});

  final Athlete athlete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initiales = [athlete.prenom, athlete.nom]
        .where((nom) => nom.trim().isNotEmpty)
        .map((nom) => nom.trim().characters.first)
        .join()
        .toUpperCase();
    return CarteSection(
      padding: const EdgeInsets.all(EspacementsApplication.moyen),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(
              initiales,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: EspacementsApplication.moyen),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(athlete.nomComplet, style: theme.textTheme.titleMedium),
                const SizedBox(height: EspacementsApplication.xs),
                Text(
                  'Athlète',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
