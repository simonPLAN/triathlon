import 'package:flutter/material.dart';

import '../../theme/espacements_application.dart';
import '../commun/carte_section.dart';

class CarteActionCoach extends StatelessWidget {
  const CarteActionCoach({
    super.key,
    required this.titre,
    required this.description,
    required this.icone,
    required this.couleur,
    required this.onTap,
  });
  final String titre;
  final String description;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CarteSection(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, size: 30, color: couleur),
          ),
          const SizedBox(height: EspacementsApplication.grand),
          Text(titre, style: theme.textTheme.titleLarge),
          const SizedBox(height: EspacementsApplication.petit),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EspacementsApplication.grand),
          Row(
            children: [
              Text(
                'Ouvrir',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, color: couleur),
            ],
          ),
        ],
      ),
    );
  }
}
