import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../controllers/epreuve_controller.dart';
import '../../widgets/epreuve/formulaire_epreuve.dart';

class CreerEpreuvePage extends StatelessWidget {
  const CreerEpreuvePage({
    super.key,
    required this.competition,
    required this.controller,
  });

  final Competition competition;
  final EpreuveController controller;

  Future<void> _creerEpreuve(
    BuildContext context,
    DonneesFormulaireEpreuve donnees,
  ) async {
    controller.effacerErreur();

    final epreuveCreee = await controller.creer(
      competitionId: competition.id,
      discipline: donnees.discipline,
      nom: donnees.nom,
      distanceMetres: donnees.distanceMetres,
      nombreManches: donnees.nombreManches,
      ordre: donnees.ordre,
      dureeLimiteSecondes: donnees.dureeLimiteSecondes,
    );

    if (!context.mounted) {
      return;
    }

    if (epreuveCreee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.erreur ?? 'L’épreuve n’a pas pu être créée.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    Navigator.of(context).pop(epreuveCreee);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return PopScope(
          canPop: !controller.creationEnCours,
          child: Scaffold(
            appBar: AppBar(title: const Text('Créer une épreuve')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EnteteCreationEpreuve(nomCompetition: competition.nom),
                        const SizedBox(height: 24),
                        if (controller.erreur != null) ...[
                          _MessageErreurEpreuve(
                            message: controller.erreur!,
                            onFermer: controller.effacerErreur,
                          ),
                          const SizedBox(height: 16),
                        ],
                        FormulaireEpreuve(
                          ordreInitial: controller.prochainOrdre(),
                          enregistrementEnCours: controller.creationEnCours,
                          onValider: (donnees) {
                            return _creerEpreuve(context, donnees);
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

class _EnteteCreationEpreuve extends StatelessWidget {
  const _EnteteCreationEpreuve({required this.nomCompetition});

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
              Icons.sports_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouvelle épreuve',
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

class _MessageErreurEpreuve extends StatelessWidget {
  const _MessageErreurEpreuve({required this.message, required this.onFermer});

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
              tooltip: 'Fermer le message',
              onPressed: onFermer,
              icon: Icon(Icons.close, color: couleurs.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
