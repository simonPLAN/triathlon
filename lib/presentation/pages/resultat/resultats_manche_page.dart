import 'package:flutter/material.dart';

import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../controllers/inscription_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';
import '../../widgets/resultat/compte_a_rebours_resultat.dart';

class ResultatsManchePage extends StatefulWidget {
  const ResultatsManchePage({
    super.key,
    required this.competition,
    required this.epreuve,
    required this.manche,
    required this.mancheController,
    required this.resultatController,
    required this.inscriptionController,
  });

  final Competition competition;
  final Epreuve epreuve;
  final Manche manche;

  final MancheController mancheController;
  final ResultatController resultatController;
  final InscriptionController inscriptionController;

  @override
  State<ResultatsManchePage> createState() {
    return _ResultatsManchePageState();
  }
}

class _ResultatsManchePageState extends State<ResultatsManchePage> {
  late Manche _manche;

  ResultatController get _resultatController {
    return widget.resultatController;
  }

  InscriptionController get _inscriptionController {
    return widget.inscriptionController;
  }

  MancheController get _mancheController {
    return widget.mancheController;
  }

  @override
  void initState() {
    super.initState();

    _manche = widget.manche;

    _resultatController.addListener(_actualiser);
    _inscriptionController.addListener(_actualiser);
    _mancheController.addListener(_actualiser);

    _chargerDonnees();
  }

  Future<void> _cloturerDelai() async {
    if (_operationEnCours) {
      return;
    }

    final heureFinDelai = _manche.heureFinDelai;

    if (heureFinDelai == null) {
      _afficherErreur('Le compte à rebours n’a pas encore démarré.');
      return;
    }

    if (DateTime.now().isBefore(heureFinDelai)) {
      _afficherErreur('Le délai n’est pas encore écoulé.');
      return;
    }

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clôturer le délai ?'),
          content: const Text(
            'Les athlètes sans résultat seront marqués '
            'hors délai avec zéro point.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Retour'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.timer_off_outlined),
              label: const Text('Clôturer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    final athletes = _inscriptionController.inscriptions
        .map((inscription) => inscription.athlete)
        .toList(growable: false);

    final nouveauxResultats = await _resultatController.marquerHorsDelai(
      manche: _manche,
      athletes: athletes,
    );

    if (!mounted) {
      return;
    }

    if (nouveauxResultats == null) {
      _afficherErreur(
        _resultatController.erreur ??
            'Les athlètes hors délai '
                'n’ont pas pu être enregistrés.',
      );
      return;
    }

    final mancheTerminee = await _mancheController.terminer(_manche);

    if (!mounted) {
      return;
    }

    if (mancheTerminee == null) {
      _afficherErreur(
        _mancheController.erreur ?? 'La manche n’a pas pu être terminée.',
      );
      return;
    }

    setState(() {
      _manche = mancheTerminee;
    });

    var message =
        '${nouveauxResultats.length} athlète(s) marqué(s) hors délai. '
        'La manche est maintenant terminée.';

    if (widget.competition.demarrageAutomatiqueMancheSuivante) {
      final manchesSuivantes =
          _mancheController.manches
              .where(
                (manche) =>
                    manche.numero > mancheTerminee.numero && manche.estAVenir,
              )
              .toList()
            ..sort((a, b) => a.numero.compareTo(b.numero));

      if (manchesSuivantes.isNotEmpty) {
        final mancheDemarree = await _mancheController.demarrer(
          manchesSuivantes.first,
        );

        if (!mounted) {
          return;
        }

        if (mancheDemarree != null) {
          message += ' La manche ${mancheDemarree.numero} a démarré.';
        } else {
          _afficherErreur(
            _mancheController.erreur ??
                'La manche suivante n’a pas pu démarrer automatiquement.',
          );
          return;
        }
      }
    }

    _afficherMessage(message);
  }

  @override
  void dispose() {
    _resultatController.removeListener(_actualiser);
    _inscriptionController.removeListener(_actualiser);
    _mancheController.removeListener(_actualiser);

    super.dispose();
  }

  void _actualiser() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _chargerDonnees() async {
    await Future.wait([
      _resultatController.charger(_manche.id),
      _inscriptionController.charger(competitionId: widget.competition.id),
    ]);
  }

  Future<void> _recharger() async {
    await _chargerDonnees();
  }

  Future<void> _enregistrerArrivee(Athlete athlete) async {
    if (_operationEnCours) {
      return;
    }

    if (!_manche.estEnCours) {
      _afficherErreur(
        'Les arrivées ne peuvent être enregistrées '
        'que pendant une manche en cours.',
      );
      return;
    }

    var manchePourResultat = _manche;

    // La première arrivée déclenche automatiquement
    // le délai configuré sur l’épreuve.
    if (_resultatController.resultats.isEmpty && !_manche.premierArrive) {
      final mancheActualisee = await _mancheController
          .enregistrerPremiereArrivee(
            manche: _manche,
            dureeLimiteSecondes: widget.epreuve.dureeLimiteSecondes,
          );

      if (!mounted) {
        return;
      }

      if (mancheActualisee == null) {
        _afficherErreur(
          _mancheController.erreur ??
              'La première arrivée n’a pas pu être '
                  'enregistrée.',
        );
        return;
      }

      setState(() {
        _manche = mancheActualisee;
      });

      manchePourResultat = mancheActualisee;
    }

    final resultat = await _resultatController.enregistrerArrivee(
      manche: manchePourResultat,
      athlete: athlete,
    );

    if (!mounted) {
      return;
    }

    if (resultat == null) {
      _afficherErreur(
        _resultatController.erreur ?? 'L’arrivée n’a pas pu être enregistrée.',
      );
      return;
    }

    _afficherMessage(
      '${athlete.nomComplet} est classé '
      '${_libellePosition(resultat.position)} '
      'avec ${resultat.points} point(s).',
    );
  }

  Future<void> _corrigerResultat(Resultat resultat) async {
    final correction = await showDialog<_CorrectionResultat>(
      context: context,
      builder: (_) => _DialogueCorrectionResultat(resultat: resultat),
    );

    if (correction == null || !mounted) {
      return;
    }

    final corrige = await _resultatController.corrigerResultat(
      resultat: resultat,
      statut: correction.statut,
      position: correction.position,
      commentaire: correction.commentaire,
    );

    if (!mounted) {
      return;
    }

    if (corrige == null) {
      _afficherErreur(
        _resultatController.erreur ?? 'Le résultat n’a pas pu être corrigé.',
      );
    } else {
      _afficherMessage('Résultat de ${resultat.athlete.nomComplet} corrigé.');
    }
  }

  void _afficherMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  bool get _operationEnCours {
    return _resultatController.operationEnCours ||
        _inscriptionController.operationEnCours ||
        _mancheController.actionEnCours;
  }

  List<Inscription> get _inscriptionsDisponibles {
    final inscriptions = _inscriptionController.inscriptions.where((
      inscription,
    ) {
      return !_resultatController.possedeResultatPour(inscription.athlete.id);
    }).toList();

    inscriptions.sort((a, b) {
      final dossardA = a.numeroDossard ?? 1 << 30;
      final dossardB = b.numeroDossard ?? 1 << 30;
      final comparaison = dossardA.compareTo(dossardB);
      return comparaison != 0
          ? comparaison
          : a.athlete.nomComplet.compareTo(b.athlete.nomComplet);
    });

    return inscriptions;
  }

  String _libellePosition(int? position) {
    if (position == null) {
      return 'sans position';
    }

    if (position == 1) {
      return '1er';
    }

    return '${position}e';
  }

  @override
  Widget build(BuildContext context) {
    final nombreInscrits = _inscriptionController.inscriptions.length;

    final nombreResultats = _resultatController.resultats.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats - Manche ${_manche.numero}'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _operationEnCours ? null : _recharger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteResultats(
              manche: _manche,
              nombreInscrits: nombreInscrits,
              nombreResultats: nombreResultats,
            ),
            if (_manche.heureFinDelai != null && _manche.estEnCours)
              CompteAReboursResultat(
                heureFinDelai: _manche.heureFinDelai!,
                onDelaiEcoule: _gererDelaiEcoule,
              ),
            if (_delaiEcoule && _manche.estEnCours)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _operationEnCours ? null : _cloturerDelai,
                    icon: const Icon(Icons.timer_off_outlined),
                    label: const Text('Clôturer le délai'),
                  ),
                ),
              ),
            Expanded(child: _construireContenu()),
          ],
        ),
      ),
    );
  }

  bool _delaiSignaleCommeEcoule = false;

  void _gererDelaiEcoule() {
    if (!mounted || _delaiSignaleCommeEcoule) {
      return;
    }

    setState(() {
      _delaiSignaleCommeEcoule = true;
    });

    _afficherMessage(
      'Le délai est écoulé. '
      'Tu peux maintenant clôturer la manche.',
    );
  }

  bool get _delaiEcoule {
    if (_delaiSignaleCommeEcoule) {
      return true;
    }

    final heureFinDelai = _manche.heureFinDelai;

    if (heureFinDelai == null) {
      return false;
    }

    return !DateTime.now().isBefore(heureFinDelai);
  }

  Widget _construireContenu() {
    if ((_resultatController.chargement || _inscriptionController.chargement) &&
        _resultatController.resultats.isEmpty) {
      return const _ChargementResultats();
    }

    if (_resultatController.erreur != null &&
        _resultatController.resultats.isEmpty) {
      return _ErreurResultats(
        message: _resultatController.erreur!,
        onReessayer: _recharger,
      );
    }

    if (_inscriptionController.erreur != null &&
        _inscriptionController.inscriptions.isEmpty) {
      return _ErreurResultats(
        message: _inscriptionController.erreur!,
        onReessayer: _recharger,
      );
    }

    if (_inscriptionController.inscriptions.isEmpty) {
      return const _AucunAthleteInscrit();
    }

    final disponibles = _inscriptionsDisponibles;
    final resultats = _resultatController.resultats;

    return RefreshIndicator(
      onRefresh: _recharger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Participants à enregistrer',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _manche.estEnCours
                ? 'Appuie directement sur un participant à son arrivée.'
                : 'La manche doit être en cours pour saisir une arrivée.',
          ),
          const SizedBox(height: 12),
          if (disponibles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Tous les participants possèdent déjà un résultat.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, contraintes) {
                final largeur = contraintes.maxWidth;
                final colonnes = largeur >= 800
                    ? 4
                    : largeur >= 520
                    ? 3
                    : 2;
                const espacement = 10.0;
                final largeurCarte =
                    (largeur - espacement * (colonnes - 1)) / colonnes;

                return Wrap(
                  spacing: espacement,
                  runSpacing: espacement,
                  children: disponibles.map((inscription) {
                    return SizedBox(
                      width: largeurCarte,
                      child: _CarteParticipantArrivee(
                        inscription: inscription,
                        active: _manche.estEnCours && !_operationEnCours,
                        onTap: () => _enregistrerArrivee(inscription.athlete),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          const SizedBox(height: 24),
          Text('Classement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (resultats.isEmpty)
            const Text('Aucune arrivée enregistrée pour le moment.')
          else
            ...resultats.map(
              (resultat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CarteResultat(
                  resultat: resultat,
                  onCorriger: () => _corrigerResultat(resultat),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CarteParticipantArrivee extends StatelessWidget {
  const _CarteParticipantArrivee({
    required this.inscription,
    required this.active,
    required this.onTap,
  });

  final Inscription inscription;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: active ? couleurs.primaryContainer : couleurs.surfaceContainer,
      child: InkWell(
        onTap: active ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  inscription.numeroDossard == null
                      ? '—'
                      : '${inscription.numeroDossard}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: active ? couleurs.onPrimaryContainer : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inscription.athlete.nomComplet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: active ? couleurs.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnteteResultats extends StatelessWidget {
  const _EnteteResultats({
    required this.manche,
    required this.nombreInscrits,
    required this.nombreResultats,
  });

  final Manche manche;
  final int nombreInscrits;
  final int nombreResultats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 38,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manche ${manche.numero}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$nombreResultats résultat(s) '
                  'sur $nombreInscrits athlète(s)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionResultat {
  const _CorrectionResultat({
    required this.statut,
    required this.position,
    required this.commentaire,
  });

  final StatutResultat statut;
  final int? position;
  final String? commentaire;
}

class _DialogueCorrectionResultat extends StatefulWidget {
  const _DialogueCorrectionResultat({required this.resultat});

  final Resultat resultat;

  @override
  State<_DialogueCorrectionResultat> createState() =>
      _DialogueCorrectionResultatState();
}

class _DialogueCorrectionResultatState
    extends State<_DialogueCorrectionResultat> {
  late StatutResultat _statut;
  late final TextEditingController _positionController;
  late final TextEditingController _commentaireController;

  @override
  void initState() {
    super.initState();
    _statut = widget.resultat.statut;
    _positionController = TextEditingController(
      text: widget.resultat.position?.toString() ?? '',
    );
    _commentaireController = TextEditingController(
      text: widget.resultat.commentaire ?? '',
    );
  }

  @override
  void dispose() {
    _positionController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionActive = _statut == StatutResultat.arrive;
    return AlertDialog(
      title: const Text('Corriger le résultat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<StatutResultat>(
              initialValue: _statut,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: StatutResultat.values
                  .map(
                    (statut) => DropdownMenuItem(
                      value: statut,
                      child: Text(_libelleStatutCorrection(statut)),
                    ),
                  )
                  .toList(),
              onChanged: (statut) {
                if (statut != null) setState(() => _statut = statut);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _positionController,
              enabled: positionActive,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentaireController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Commentaire'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final position = int.tryParse(_positionController.text.trim());
            if (positionActive && (position == null || position <= 0)) {
              return;
            }
            Navigator.of(context).pop(
              _CorrectionResultat(
                statut: _statut,
                position: positionActive ? position : null,
                commentaire: _commentaireController.text,
              ),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  String _libelleStatutCorrection(StatutResultat statut) {
    switch (statut) {
      case StatutResultat.arrive:
        return 'Arrivé';
      case StatutResultat.horsDelai:
        return 'Hors délai';
      case StatutResultat.abandon:
        return 'Abandon';
      case StatutResultat.disqualifie:
        return 'Disqualifié';
    }
  }
}

class _CarteResultat extends StatelessWidget {
  const _CarteResultat({required this.resultat, required this.onCorriger});

  final Resultat resultat;
  final VoidCallback onCorriger;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            _PositionResultat(resultat: resultat),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultat.athlete.nomComplet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _libelleStatut(resultat),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (resultat.heureArrivee != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Arrivée à '
                      '${_formaterHeure(resultat.heureArrivee!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (resultat.tempsTotalMillisecondes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Temps : '
                      '${_formaterDuree(resultat.tempsTotalMillisecondes!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Corriger le résultat',
              onPressed: onCorriger,
              icon: const Icon(Icons.edit_outlined),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${resultat.points} pt'
                '${resultat.points > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _libelleStatut(Resultat resultat) {
    switch (resultat.statut) {
      case StatutResultat.arrive:
        return 'Arrivé';

      case StatutResultat.horsDelai:
        return 'Hors délai';

      case StatutResultat.abandon:
        return 'Abandon';

      case StatutResultat.disqualifie:
        return 'Disqualifié';
    }
  }

  String _formaterHeure(DateTime date) {
    final heure = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    final seconde = date.second.toString().padLeft(2, '0');

    return '$heure:$minute:$seconde';
  }

  String _formaterDuree(int millisecondes) {
    final duree = Duration(milliseconds: millisecondes);

    final minutes = duree.inMinutes.toString().padLeft(2, '0');

    final secondes = duree.inSeconds.remainder(60).toString().padLeft(2, '0');

    final milliemes = duree.inMilliseconds
        .remainder(1000)
        .toString()
        .padLeft(3, '0');

    return '$minutes:$secondes.$milliemes';
  }
}

class _PositionResultat extends StatelessWidget {
  const _PositionResultat({required this.resultat});

  final Resultat resultat;

  @override
  Widget build(BuildContext context) {
    final position = resultat.position;

    return CircleAvatar(
      radius: 25,
      backgroundColor: position == 1
          ? Colors.amber.shade200
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: position == null
          ? const Icon(Icons.remove)
          : Text(
              '$position',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
    );
  }
}

class _ChargementResultats extends StatelessWidget {
  const _ChargementResultats();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des résultats...'),
        ],
      ),
    );
  }
}

class _ErreurResultats extends StatelessWidget {
  const _ErreurResultats({required this.message, required this.onReessayer});

  final String message;
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await onReessayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AucunAthleteInscrit extends StatelessWidget {
  const _AucunAthleteInscrit();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Aucun athlète n’est inscrit '
          'à cette compétition.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
