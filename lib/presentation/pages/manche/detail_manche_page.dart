import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/manche.dart';
import '../../controllers/manche_controller.dart';
import '../../widgets/manche/actions_manche.dart';
import '../../widgets/manche/badge_statut_manche.dart';
import '../../widgets/manche/chronometre_manche.dart';
import '../../widgets/manche/informations_manche.dart';

class DetailManchePage extends StatefulWidget {
  const DetailManchePage({
    super.key,
    required this.competition,
    required this.epreuve,
    required this.manche,
    required this.controller,
  });

  final Competition competition;
  final Epreuve epreuve;
  final Manche manche;
  final MancheController controller;

  @override
  State<DetailManchePage> createState() {
    return _DetailManchePageState();
  }
}

class _DetailManchePageState extends State<DetailManchePage> {
  late Manche _manche;

  @override
  void initState() {
    super.initState();
    _manche = widget.manche;
  }

  Future<void> _demarrer() async {
    final mancheActualisee = await widget.controller.demarrer(_manche);

    _traiterResultatAction(mancheActualisee, 'La manche a démarré.');
  }

  Future<void> _enregistrerPremiereArrivee() async {
    final mancheActualisee = await widget.controller.enregistrerPremiereArrivee(
      manche: _manche,
      dureeLimiteSecondes: widget.epreuve.dureeLimiteSecondes,
    );

    _traiterResultatAction(
      mancheActualisee,
      'La première arrivée a été enregistrée. '
      'Le compte à rebours est démarré.',
    );
  }

  Future<void> _terminer() async {
    final confirmation = await _confirmerAction(
      titre: 'Terminer la manche ?',
      message:
          'Les arrivées restantes devront être traitées '
          'comme hors délai si nécessaire.',
      libelleConfirmation: 'Terminer',
    );

    if (!confirmation) {
      return;
    }

    final mancheActualisee = await widget.controller.terminer(_manche);

    _traiterResultatAction(mancheActualisee, 'La manche est terminée.');
  }

  Future<void> _annuler() async {
    final confirmation = await _confirmerAction(
      titre: 'Annuler la manche ?',
      message:
          'La manche ${_manche.numero} sera marquée '
          'comme annulée.',
      libelleConfirmation: 'Annuler la manche',
      actionDangereuse: true,
    );

    if (!confirmation) {
      return;
    }

    final mancheActualisee = await widget.controller.annuler(_manche);

    _traiterResultatAction(mancheActualisee, 'La manche a été annulée.');
  }

  Future<void> _publierResultats() async {
    final confirmation = await _confirmerAction(
      titre: 'Publier les résultats ?',
      message:
          'Les résultats de cette manche deviendront '
          'visibles pour les utilisateurs autorisés.',
      libelleConfirmation: 'Publier',
    );

    if (!confirmation) {
      return;
    }

    final mancheActualisee = await widget.controller.publierResultats(_manche);

    _traiterResultatAction(mancheActualisee, 'Les résultats ont été publiés.');
  }

  void _traiterResultatAction(Manche? mancheActualisee, String messageSucces) {
    if (!mounted) {
      return;
    }

    if (mancheActualisee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.erreur ?? 'L’action n’a pas pu être effectuée.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    setState(() {
      _manche = mancheActualisee;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messageSucces)));
  }

  Future<bool> _confirmerAction({
    required String titre,
    required String message,
    required String libelleConfirmation,
    bool actionDangereuse = false,
  }) async {
    final resultat = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titre),
          content: Text(message),
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
              style: actionDangereuse
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              child: Text(libelleConfirmation),
            ),
          ],
        );
      },
    );

    return resultat ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return PopScope(
          canPop: !widget.controller.actionEnCours,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }

            if (!widget.controller.actionEnCours) {
              Navigator.of(context).pop(_manche);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Manche ${_manche.numero}'),
              leading: IconButton(
                tooltip: 'Retour',
                onPressed: widget.controller.actionEnCours
                    ? null
                    : () {
                        Navigator.of(context).pop(_manche);
                      },
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _EnteteManche(epreuve: widget.epreuve, manche: _manche),
                  const SizedBox(height: 16),
                  if (_manche.delaiDemarre && _manche.estEnCours)
                    ChronometreManche(heureFinDelai: _manche.heureFinDelai!),
                  if (_manche.delaiDemarre && _manche.estEnCours)
                    const SizedBox(height: 16),
                  InformationsManche(manche: _manche),
                  const SizedBox(height: 16),
                  ActionsManche(
                    manche: _manche,
                    actionEnCours: widget.controller.actionEnCours,
                    onDemarrer: _demarrer,
                    onPremiereArrivee: _enregistrerPremiereArrivee,
                    onTerminer: _terminer,
                    onAnnuler: _annuler,
                    onPublierResultats: _publierResultats,
                  ),
                  if (widget.controller.erreur != null) ...[
                    const SizedBox(height: 16),
                    _MessageErreurManche(
                      message: widget.controller.erreur!,
                      onFermer: widget.controller.effacerErreur,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnteteManche extends StatelessWidget {
  const _EnteteManche({required this.epreuve, required this.manche});

  final Epreuve epreuve;
  final Manche manche;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${manche.numero}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    epreuve.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  BadgeStatutManche(statut: manche.statut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageErreurManche extends StatelessWidget {
  const _MessageErreurManche({required this.message, required this.onFermer});

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
