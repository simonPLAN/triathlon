import 'package:flutter/material.dart';

import 'carte_action_coach.dart';

class GrilleActionsCoach extends StatelessWidget {
  const GrilleActionsCoach({
    super.key,
    required this.onVoirCompetitions,
    required this.onVoirAthletes,
  });

  final VoidCallback onVoirCompetitions;
  final VoidCallback onVoirAthletes;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final cartes = [
      CarteActionCoach(
        titre: 'Mes compétitions',
        description: 'Organisez vos épreuves, gérez les inscriptions et consultez les résultats.',
        icone: Icons.emoji_events_outlined,
        couleur: couleurs.primary,
        onTap: onVoirCompetitions,
      ),
      CarteActionCoach(
        titre: 'Athlètes',
        description:
            'Retrouvez les profils et gérez les athlètes de votre club.',
        icone: Icons.groups_outlined,
        couleur: couleurs.secondary,
        onTap: onVoirAthletes,
      ),
    ];
    return LayoutBuilder(
      builder: (context, contraintes) {
        if (contraintes.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cartes[0], const SizedBox(height: 16), cartes[1]],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cartes[0]),
            const SizedBox(width: 16),
            Expanded(child: cartes[1]),
          ],
        );
      },
    );
  }
}
