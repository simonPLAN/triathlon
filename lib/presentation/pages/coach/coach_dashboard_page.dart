import 'package:flutter/material.dart';

import '../../../application/use_cases/deconnecter_utilisateur.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../widgets/coach/entete_coach.dart';
import '../../widgets/coach/etapes_coach.dart';
import '../../widgets/coach/grille_actions_coach.dart';

class CoachDashboardPage extends StatelessWidget {
  const CoachDashboardPage({
    super.key,
    required this.profil,
    required this.deconnecterUtilisateur,
    required this.onVoirCompetitions,
    required this.onVoirAthletes,
  });

  final ProfilUtilisateur profil;
  final DeconnecterUtilisateur deconnecterUtilisateur;
  final VoidCallback onVoirCompetitions;
  final VoidCallback onVoirAthletes;

  Future<void> _deconnecter(BuildContext context) async {
    try {
      await deconnecterUtilisateur.executer();
    } catch (exception) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _afficherFonctionnaliteEnPreparation(
    BuildContext context,
    String fonctionnalite,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fonctionnalite sera ajoutée prochainement.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace coach'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: () => _deconnecter(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EnteteCoach(profil: profil),
            const SizedBox(height: 24),
            Text('Gestion', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GrilleActionsCoach(
              onVoirCompetitions: onVoirCompetitions,
              onVoirAthletes: onVoirAthletes,
              onVoirManches: () {
                _afficherFonctionnaliteEnPreparation(
                  context,
                  'La gestion des manches',
                );
              },
              onVoirResultats: () {
                _afficherFonctionnaliteEnPreparation(
                  context,
                  'La gestion des résultats',
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Démarrage rapide',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const EtapesCoach(),
          ],
        ),
      ),
    );
  }
}
