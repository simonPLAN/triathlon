import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';

class ActionsStatutCompetition extends StatelessWidget {
  const ActionsStatutCompetition({
    super.key,
    required this.competition,
    required this.changementEnCours,
    required this.onChangerStatut,
  });

  final Competition competition;
  final bool changementEnCours;

  final Future<void> Function(StatutCompetition nouveauStatut) onChangerStatut;

  @override
  Widget build(BuildContext context) {
    if (competition.estTerminee || competition.estAnnulee) {
      return _StatutFinal(competition: competition);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'État de la compétition',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _descriptionStatut(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_prochainStatut != null)
              FilledButton.icon(
                onPressed: changementEnCours
                    ? null
                    : () async {
                        final prochainStatut = _prochainStatut;

                        if (prochainStatut == null) {
                          return;
                        }

                        await onChangerStatut(prochainStatut);
                      },
                icon: changementEnCours
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_iconeActionPrincipale),
                label: Text(
                  changementEnCours
                      ? 'Modification...'
                      : _libelleActionPrincipale,
                ),
              ),
            if (competition.estOuverte) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: changementEnCours
                    ? null
                    : () => _confirmerRetourBrouillon(context),
                icon: const Icon(Icons.undo_outlined),
                label: const Text('Revenir en brouillon'),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: changementEnCours
                  ? null
                  : () async {
                      await _confirmerAnnulation(context);
                    },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Annuler la compétition'),
            ),
          ],
        ),
      ),
    );
  }

  StatutCompetition? get _prochainStatut {
    switch (competition.statut) {
      case StatutCompetition.brouillon:
        return StatutCompetition.ouverte;

      case StatutCompetition.ouverte:
        return StatutCompetition.enCours;

      case StatutCompetition.enCours:
        return StatutCompetition.terminee;

      case StatutCompetition.terminee:
      case StatutCompetition.annulee:
        return null;
    }
  }

  String get _libelleActionPrincipale {
    switch (competition.statut) {
      case StatutCompetition.brouillon:
        return 'Ouvrir les inscriptions';

      case StatutCompetition.ouverte:
        return 'Démarrer la compétition';

      case StatutCompetition.enCours:
        return 'Terminer la compétition';

      case StatutCompetition.terminee:
      case StatutCompetition.annulee:
        return '';
    }
  }

  IconData get _iconeActionPrincipale {
    switch (competition.statut) {
      case StatutCompetition.brouillon:
        return Icons.how_to_reg_outlined;

      case StatutCompetition.ouverte:
        return Icons.play_arrow;

      case StatutCompetition.enCours:
        return Icons.flag_outlined;

      case StatutCompetition.terminee:
      case StatutCompetition.annulee:
        return Icons.check;
    }
  }

  String _descriptionStatut() {
    switch (competition.statut) {
      case StatutCompetition.brouillon:
        return 'La compétition est en préparation. '
            'Ouvre-la lorsque les inscriptions peuvent commencer.';

      case StatutCompetition.ouverte:
        return 'Les inscriptions sont ouvertes. '
            'Démarre la compétition lorsque tout est prêt.';

      case StatutCompetition.enCours:
        return 'La compétition est en cours. '
            'Termine-la lorsque toutes les manches sont validées.';

      case StatutCompetition.terminee:
        return 'La compétition est terminée.';

      case StatutCompetition.annulee:
        return 'La compétition a été annulée.';
    }
  }

  Future<void> _confirmerRetourBrouillon(BuildContext context) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revenir en brouillon ?'),
        content: const Text(
          'Les nouvelles inscriptions seront fermées. Les inscriptions déjà '
          'enregistrées seront conservées et la configuration redeviendra '
          'modifiable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Garder les inscriptions ouvertes'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revenir en brouillon'),
          ),
        ],
      ),
    );
    if (confirmer == true) {
      await onChangerStatut(StatutCompetition.brouillon);
    }
  }

  Future<void> _confirmerAnnulation(BuildContext context) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Annuler la compétition ?'),
          content: Text(
            'La compétition « ${competition.nom} » '
            'passera au statut annulée.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Retour'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Confirmer l’annulation'),
            ),
          ],
        );
      },
    );

    if (confirmer == true) {
      await onChangerStatut(StatutCompetition.annulee);
    }
  }
}

class _StatutFinal extends StatelessWidget {
  const _StatutFinal({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final estTerminee = competition.estTerminee;

    final couleur = estTerminee
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              estTerminee ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: couleur,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                estTerminee
                    ? 'Cette compétition est terminée.'
                    : 'Cette compétition est annulée.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
