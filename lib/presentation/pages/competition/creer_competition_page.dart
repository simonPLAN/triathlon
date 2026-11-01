import 'package:flutter/material.dart';

import '../../../domain/entities/profil_utilisateur.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/competition/formulaire_competition.dart';

class CreerCompetitionPage extends StatelessWidget {
  const CreerCompetitionPage({
    super.key,
    required this.controller,
    required this.profilCoach,
  });

  final CompetitionController controller;
  final ProfilUtilisateur profilCoach;

  Future<void> _creerCompetition(
    BuildContext context,
    DonneesFormulaireCompetition donnees,
  ) async {
    controller.effacerErreur();

    final succes = await controller.creer(
      nom: donnees.nom,
      description: donnees.description,
      lieu: donnees.lieu,
      dateCompetition: donnees.dateCompetition,
      coachId: profilCoach.id,
    );

    if (!context.mounted) {
      return;
    }

    if (succes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La compétition a été créée.')),
      );

      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.erreur ?? 'La compétition n’a pas pu être créée.',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<bool> _confirmerFermeture(BuildContext context) async {
    if (controller.creationEnCours) {
      return false;
    }

    final quitter = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Quitter la création ?'),
          content: const Text(
            'Les informations saisies ne seront pas enregistrées.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Continuer'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );

    return quitter ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return;
            }

            final quitter = await _confirmerFermeture(context);

            if (quitter && context.mounted) {
              Navigator.of(context).pop(false);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Créer une compétition'),
              leading: IconButton(
                tooltip: 'Fermer',
                onPressed: controller.creationEnCours
                    ? null
                    : () async {
                        final quitter = await _confirmerFermeture(context);

                        if (quitter && context.mounted) {
                          Navigator.of(context).pop(false);
                        }
                      },
                icon: const Icon(Icons.close),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EnteteCreationCompetition(profilCoach: profilCoach),
                        const SizedBox(height: 24),
                        if (controller.erreur != null) ...[
                          _MessageErreur(
                            message: controller.erreur!,
                            onFermer: controller.effacerErreur,
                          ),
                          const SizedBox(height: 16),
                        ],
                        FormulaireCompetition(
                          enregistrementEnCours: controller.creationEnCours,
                          onValider: (donnees) {
                            return _creerCompetition(context, donnees);
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

class _EnteteCreationCompetition extends StatelessWidget {
  const _EnteteCreationCompetition({required this.profilCoach});

  final ProfilUtilisateur profilCoach;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouvelle compétition',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Créée par ${profilCoach.nomComplet}',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _MessageErreur extends StatelessWidget {
  const _MessageErreur({required this.message, required this.onFermer});

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
