import 'package:flutter/material.dart';

import '../../../application/use_cases/deconnecter_utilisateur.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../widgets/coach/entete_coach.dart';
import '../compte/informations_application_page.dart';
import '../../widgets/coach/grille_actions_coach.dart';
import '../../widgets/commun/menu_compte_application.dart';

class CoachDashboardPage extends StatefulWidget {
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

  @override
  State<CoachDashboardPage> createState() => _CoachDashboardPageState();
}

class _CoachDashboardPageState extends State<CoachDashboardPage> {
  bool _deconnexionEnCours = false;

  Future<void> _deconnecter() async {
    if (_deconnexionEnCours) return;
    setState(() => _deconnexionEnCours = true);
    try {
      await widget.deconnecterUtilisateur.executer();
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('La déconnexion a échoué. Réessaie.')),
      );
    } finally {
      if (mounted) setState(() => _deconnexionEnCours = false);
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
            tooltip: 'Informations',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => InformationsApplicationPage(
                  onSupprimerCompte: widget.onMonCompte,
                ),
              ),
            ),
          ),
          MenuCompteApplication(
            onDeconnecter: _deconnecter,
            onSupprimerCompte: widget.onMonCompte,
            operationEnCours: _deconnexionEnCours,
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
                  EnteteCoach(profil: widget.profil),
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
                    onVoirCompetitions: widget.onVoirCompetitions,
                    onVoirAthletes: widget.onVoirAthletes,
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
