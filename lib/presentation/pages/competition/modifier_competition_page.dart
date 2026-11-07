import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/competition/formulaire_competition.dart';

class ModifierCompetitionPage extends StatelessWidget {
  const ModifierCompetitionPage({
    super.key,
    required this.competition,
    required this.controller,
  });

  final Competition competition;
  final CompetitionController controller;

  Future<void> _modifierCompetition(
    BuildContext context,
    DonneesFormulaireCompetition donnees,
  ) async {
    controller.effacerErreur();

    final competitionModifiee = await controller.modifier(
      competition: competition,
      nom: donnees.nom,
      description: donnees.description,
      lieu: donnees.lieu,
      dateCompetition: donnees.dateCompetition,
      demarrageAutomatiqueMancheSuivante:
          donnees.demarrageAutomatiqueMancheSuivante,
    );

    if (!context.mounted) {
      return;
    }

    if (competitionModifiee != null) {
      Navigator.of(context).pop(competitionModifiee);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.erreur ?? 'La compétition n’a pas pu être modifiée.',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return PopScope(
          canPop: !controller.modificationEnCours,
          child: Scaffold(
            appBar: AppBar(title: const Text('Modifier la compétition')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EnteteModification(nomCompetition: competition.nom),
                        const SizedBox(height: 24),
                        if (controller.erreur != null) ...[
                          _MessageErreurModification(
                            message: controller.erreur!,
                            onFermer: controller.effacerErreur,
                          ),
                          const SizedBox(height: 16),
                        ],
                        FormulaireCompetition(
                          nomInitial: competition.nom,
                          descriptionInitiale: competition.description ?? '',
                          lieuInitial: competition.lieu ?? '',
                          dateInitiale: competition.dateCompetition,
                          demarrageAutomatiqueInitial:
                              competition.demarrageAutomatiqueMancheSuivante,
                          enregistrementEnCours: controller.modificationEnCours,
                          libelleBouton: 'Enregistrer les modifications',
                          onValider: (donnees) {
                            return _modifierCompetition(context, donnees);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnteteModification extends StatelessWidget {
  const _EnteteModification({required this.nomCompetition});

  final String nomCompetition;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.edit_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modification',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nomCompetition,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageErreurModification extends StatelessWidget {
  const _MessageErreurModification({
    required this.message,
    required this.onFermer,
  });

  final String message;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Material(
      color: couleurs.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: couleurs.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: couleurs.onErrorContainer),
              ),
            ),
            IconButton(
              tooltip: 'Fermer',
              onPressed: onFermer,
              icon: Icon(Icons.close, color: couleurs.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
