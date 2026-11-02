import 'package:flutter/material.dart';

import '../../../application/use_cases/deconnecter_utilisateur.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../widgets/coach/entete_coach.dart';
import '../../widgets/coach/grille_actions_coach.dart';

class CoachDashboardPage extends StatelessWidget {
  const CoachDashboardPage({
    super.key,
    required this.profil,
    this.onMonCompte,
    required this.deconnecterUtilisateur,
    required this.onVoirCompetitions,
    required this.onVoirAthletes,
  });

  final ProfilUtilisateur profil;
  final VoidCallback? onMonCompte;
  final DeconnecterUtilisateur deconnecterUtilisateur;
  final VoidCallback onVoirCompetitions;
  final VoidCallback onVoirAthletes;

  Future<void> _deconnecter(BuildContext context) async {
    try {
      await deconnecterUtilisateur.executer();
    } catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Espace coach'),
        actions: [
          IconButton(
            tooltip: 'Supprimer mon compte',
            onPressed: onMonCompte,
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: () => _deconnecter(context),
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EnteteCoach(profil: profil),
                  const SizedBox(height: 32),
                  Text(
                    'Votre espace de gestion',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retrouvez vos événements et les athlètes de votre club.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GrilleActionsCoach(
                    onVoirCompetitions: onVoirCompetitions,
                    onVoirAthletes: onVoirAthletes,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
