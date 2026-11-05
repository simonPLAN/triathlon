import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/manche.dart';
import '../../controllers/inscription_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';
import '../../widgets/manche/actions_manche.dart';
import '../../widgets/manche/configurer_participants_dialog.dart';
import '../../widgets/manche/badge_statut_manche.dart';
import '../../widgets/manche/chronometre_manche.dart';
import '../../widgets/manche/informations_manche.dart';
import '../resultat/resultats_manche_page.dart';

class DetailManchePage extends StatefulWidget {
  const DetailManchePage({
    super.key,
    required this.competition,
    required this.epreuve,
    required this.manche,
    required this.controller,
    required this.resultatController,
    required this.inscriptionController,
  });

  final Competition competition;
  final Epreuve epreuve;
  final Manche manche;

  final MancheController controller;
  final ResultatController resultatController;
  final InscriptionController inscriptionController;

  @override
  State<DetailManchePage> createState() {
    return _DetailManchePageState();
  }
}

class _DetailManchePageState extends State<DetailManchePage> {
  late Manche _manche;
  bool _configurationEnCours = false;

  @override
  void initState() {
    super.initState();

    _manche = widget.manche;
  }

  Future<void> _configurer() async {
    if (_configurationEnCours || widget.controller.actionEnCours) return;
    setState(() => _configurationEnCours = true);
    try {
    await widget.inscriptionController.charger(competitionId: widget.competition.id);
    if (!mounted) return;
    if (widget.inscriptionController.erreur != null) {
      _afficherErreur(widget.inscriptionController.erreur!);
      return;
    }
    final choix = await showDialog<ConfigurationParticipants>(context: context,
      builder: (_) => ConfigurerParticipantsDialog(manche: _manche,
        inscriptions: widget.inscriptionController.inscriptions,
        dureeParDefaut: widget.epreuve.dureeLimiteSecondes));
    if (choix == null || !mounted) return;
    final modifiee = await widget.controller.configurer(manche: _manche,
      athleteIds: choix.athleteIds, dureeLimiteSecondes: choix.dureeLimiteSecondes);
    _traiterResultatAction(modifiee, 'Participants, départs et délai enregistrés.');
    } finally {
      if (mounted) setState(() => _configurationEnCours = false);
    }
  }

  Future<void> _demarrer() async {
    final mancheActualisee = await widget.controller.demarrer(_manche);

    _traiterResultatAction(mancheActualisee, 'La manche a démarré.');
  }

  Future<void> _terminer() async {
    if (!_manche.premierArrive) {
      _afficherErreur(
        'La manche ne peut pas être terminée '
        'avant l’enregistrement d’une arrivée.',
      );
      return;
    }

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

    if (mancheActualisee == null || !mounted) {
      _traiterResultatAction(mancheActualisee, 'La manche est terminée.');
      return;
    }

    var message = 'La manche est terminée.';

    if (widget.competition.demarrageAutomatiqueMancheSuivante) {
      final manchesSuivantes =
          widget.controller.manches
              .where(
                (manche) =>
                    manche.numero > mancheActualisee.numero && manche.estAVenir,
              )
              .toList()
            ..sort((a, b) => a.numero.compareTo(b.numero));

      if (manchesSuivantes.isNotEmpty) {
        final mancheDemarree = await widget.controller.demarrer(
          manchesSuivantes.first,
        );

        if (!mounted) {
          return;
        }

        if (mancheDemarree == null) {
          _afficherErreur(
            widget.controller.erreur ??
                'La manche suivante n’a pas pu démarrer automatiquement.',
          );
        } else {
          message += ' La manche ${mancheDemarree.numero} a démarré.';
        }
      }
    }

    _traiterResultatAction(mancheActualisee, message);
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

  Future<void> _validerResultats() async {
    final confirmation = await _confirmerAction(titre: 'Valider le classement ?',
      message: 'Vérifie les résultats de chaque participant. Une correction rendra cette validation caduque et imposera une nouvelle validation.',
      libelleConfirmation: 'Valider');
    if (!confirmation) return;
    final validee = await widget.controller.validerResultats(_manche);
    _traiterResultatAction(validee, 'Classement validé. Il peut maintenant être publié.');
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

  Future<void> _ouvrirResultats() async {
    widget.resultatController.reinitialiser();

    final mancheActualisee = await Navigator.of(context).push<Manche>(
      MaterialPageRoute<Manche>(
        builder: (context) {
          return ResultatsManchePage(
            competition: widget.competition,
            epreuve: widget.epreuve,
            manche: _manche,
            mancheController: widget.controller,
            resultatController: widget.resultatController,
            inscriptionController: widget.inscriptionController,
          );
        },
      ),
    );

    if (!mounted) return;
    final actualisee =
        mancheActualisee ??
        widget.controller.manches.where((m) => m.id == _manche.id).firstOrNull;
    if (actualisee == null) return;
    setState(() => _manche = actualisee);
  }

  void _traiterResultatAction(Manche? mancheActualisee, String messageSucces) {
    if (!mounted) {
      return;
    }

    if (mancheActualisee == null) {
      _afficherErreur(
        widget.controller.erreur ?? 'L’action n’a pas pu être effectuée.',
      );
      return;
    }

    setState(() {
      _manche = mancheActualisee;
    });

    widget.controller.remplacerLocalement(mancheActualisee);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messageSucces)));
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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

  void _retournerVersListe() {
    if (widget.controller.actionEnCours) {
      return;
    }

    Navigator.of(context).pop(_manche);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }

            _retournerVersListe();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Manche ${_manche.numero}'),
              leading: IconButton(
                tooltip: 'Retour',
                onPressed: widget.controller.actionEnCours
                    ? null
                    : _retournerVersListe,
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
                    ChronometreManche(
                      key: ValueKey(_manche.id),
                      heureFinDelai: _manche.heureFinDelai!,
                      onDelaiEcoule: () {
                        if (ModalRoute.of(context)?.isCurrent == true) {
                          _ouvrirResultats();
                        }
                      },
                    ),

                  if (_manche.delaiDemarre && _manche.estEnCours)
                    const SizedBox(height: 16),

                  InformationsManche(manche: _manche),
                  const SizedBox(height: 8),
                  Text(_manche.participantsDefinis
                      ? '${_manche.participantsAthleteIds.length} participants affectés · délai ${_manche.dureeLimiteSecondes ?? widget.epreuve.dureeLimiteSecondes} s'
                      : 'Participants non configurés'),
                  if (_manche.estAVenir)
                    OutlinedButton.icon(onPressed: widget.controller.actionEnCours || _configurationEnCours ? null : _configurer,
                      icon: _configurationEnCours ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.people_outline), label: Text(_configurationEnCours ? 'Chargement des participants…' : 'Participants et ordre de départ'))
                  else
                    const Text('Les affectations et le délai sont figés après le départ.'),
                  const SizedBox(height: 16),

                  if (_manche.estTerminee && _manche.validationRequise && !_manche.resultatsValides)
                    FilledButton.icon(onPressed: widget.controller.actionEnCours ? null : _validerResultats,
                      icon: const Icon(Icons.fact_check_outlined), label: const Text('Valider le classement')),
                  if (_manche.estTerminee)
                    Text(_manche.resultatsPublies ? 'Résultats publiés' : _manche.resultatsValides ? 'Résultats validés, non publiés' : 'Résultats provisoires'),
                  ActionsManche(
                    manche: _manche,
                    actionEnCours: widget.controller.actionEnCours,
                    onDemarrer: _demarrer,
                    onTerminer: _terminer,
                    onAnnuler: _annuler,
                    onPublierResultats: _publierResultats,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.controller.actionEnCours
                          ? null
                          : _manche.estEnCours || _manche.estTerminee
                          ? _ouvrirResultats
                          : null,
                      icon: Icon(
                        _manche.estEnCours
                            ? Icons.flag_outlined
                            : Icons.leaderboard_outlined,
                      ),
                      label: Text(
                        _manche.estEnCours
                            ? 'Saisir les arrivées'
                            : 'Consulter les résultats',
                      ),
                    ),
                  ),

                  if (_manche.estEnCours && !_manche.premierArrive) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Le premier athlète enregistré '
                      'déclenchera automatiquement '
                      'le compte à rebours.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

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
