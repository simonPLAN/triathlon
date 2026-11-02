import 'package:flutter/material.dart';

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
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(icone, size: 30, color: couleur),
                ),
              ),
              const SizedBox(height: 24),
              Text(titre, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Ouvrir',
                    style: theme.textTheme.labelLarge?.copyWith(color: couleur),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: couleur),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
