import 'package:flutter/material.dart';

import 'carte_action_coach.dart';

class GrilleActionsCoach extends StatelessWidget {
  const GrilleActionsCoach({
    super.key,
    required this.onVoirCompetitions,
    required this.onVoirAthletes,
    required this.onVoirManches,
    required this.onVoirResultats,
  });

  final VoidCallback onVoirCompetitions;
  final VoidCallback onVoirAthletes;
  final VoidCallback onVoirManches;
  final VoidCallback onVoirResultats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final nombreColonnes = contraintes.maxWidth >= 700 ? 4 : 2;

        return GridView.count(
          crossAxisCount: nombreColonnes,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            CarteActionCoach(
              titre: 'Compétitions',
              description: 'Créer et organiser',
              icone: Icons.emoji_events,
              couleur: Colors.orange,
              onTap: onVoirCompetitions,
            ),
            CarteActionCoach(
              titre: 'Athlètes',
              description: 'Consulter les inscrits',
              icone: Icons.groups,
              couleur: Colors.blue,
              onTap: onVoirAthletes,
            ),
            CarteActionCoach(
              titre: 'Manches',
              description: 'Gérer les départs',
              icone: Icons.timer,
              couleur: Colors.green,
              onTap: onVoirManches,
            ),
            CarteActionCoach(
              titre: 'Résultats',
              description: 'Saisir et publier',
              icone: Icons.leaderboard,
              couleur: Colors.purple,
              onTap: onVoirResultats,
            ),
          ],
        );
      },
    );
  }
}
