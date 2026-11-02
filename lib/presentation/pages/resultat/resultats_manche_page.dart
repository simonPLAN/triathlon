import 'package:flutter/material.dart';

import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../controllers/inscription_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';
import '../../widgets/resultat/compte_a_rebours_resultat.dart';
import '../../widgets/resultat/cartes_resultat.dart';
import '../../widgets/resultat/etats_resultats.dart';

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
    final correction = await showDialog<CorrectionResultat>(
      context: context,
      builder: (_) => DialogueCorrectionResultat(resultat: resultat),
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
            EnteteResultats(
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
      return const ChargementResultats();
    }

    if (_resultatController.erreur != null &&
        _resultatController.resultats.isEmpty) {
      return ErreurResultats(
        message: _resultatController.erreur!,
        onReessayer: _recharger,
      );
    }

    if (_inscriptionController.erreur != null &&
        _inscriptionController.inscriptions.isEmpty) {
      return ErreurResultats(
        message: _inscriptionController.erreur!,
        onReessayer: _recharger,
      );
    }

    if (_inscriptionController.inscriptions.isEmpty) {
      return const AucunAthleteInscrit();
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
                      child: CarteParticipantArrivee(
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
                child: CarteResultat(
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
