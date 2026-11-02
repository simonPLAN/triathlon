import 'package:flutter/material.dart';

import '../../../domain/entities/profil_utilisateur.dart';

class EnteteCoach extends StatelessWidget {
  const EnteteCoach({super.key, required this.profil});

  final ProfilUtilisateur profil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleurs.primaryContainer, couleurs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_outlined, color: couleurs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'COACH',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: couleurs.onPrimaryContainer,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Bonjour ${profil.prenom}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: couleurs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vos compétitions, votre équipe, une seule vue.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: couleurs.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
