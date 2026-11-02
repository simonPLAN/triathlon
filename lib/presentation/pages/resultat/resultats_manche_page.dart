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
import '../../widgets/resultat/dialogue_correction_resultat.dart';
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
  bool _clotureEnCours = false;
  bool _chargementDonnees = true;
  bool _clotureDemandee = false;

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
    if (_operationEnCours || !_manche.estEnCours) {
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

    setState(() {
      _clotureEnCours = true;
      _clotureDemandee = false;
    });
    try {
      if (_inscriptionController.erreur != null ||
          _resultatController.erreur != null) {
        _afficherErreur(
          'Recharge les participants avant de réessayer la clôture.',
        );
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
            setState(() {
              _manche = mancheDemarree;
              _delaiSignaleCommeEcoule = false;
            });
            _resultatController.reinitialiser();
            await _resultatController.charger(mancheDemarree.id);
            if (!mounted) return;
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
    } finally {
      if (mounted) {
        setState(() => _clotureEnCours = false);
      }
    }
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
      if (_clotureDemandee && !_operationEnCours) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _clotureDemandee) _cloturerDelai();
        });
      }
    }
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargementDonnees = true);
    await Future.wait([
      _resultatController.charger(_manche.id),
      _inscriptionController.charger(competitionId: widget.competition.id),
      _mancheController.charger(widget.epreuve.id),
    ]);
    if (!mounted) return;
    setState(() {
      _chargementDonnees = false;
      for (final manche in _mancheController.manches) {
        if (manche.id == _manche.id) _manche = manche;
      }
    });
    if (_manche.estEnCours && _delaiEcoule) {
      _gererDelaiEcoule();
    }
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

    if (_delaiEcoule) {
      _gererDelaiEcoule();
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

  Future<void> _saisirManuellement() async {
    if (_operationEnCours || !_manche.estTerminee) return;
    final athlete = await showDialog<Athlete>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choisir un participant'),
        children: _inscriptionController.inscriptions
            .map(
              (i) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(i.athlete),
                child: Text(
                  '${i.numeroDossard == null ? '' : 'N°${i.numeroDossard} · '}${i.athlete.nomComplet}',
                ),
              ),
            )
            .toList(),
      ),
    );
    if (athlete == null || !mounted) return;
    await _editerResultat(
      athlete,
      resultat: _resultatController.resultatPour(athlete.id),
    );
  }

  Future<void> _editerResultat(Athlete athlete, {Resultat? resultat}) async {
    if (_operationEnCours || !_manche.estTerminee) return;
    final mancheId = _manche.id;
    final correction = await showDialog<CorrectionResultat>(
      context: context,
      builder: (_) => DialogueCorrectionResultat(
        manche: _manche,
        athlete: athlete,
        resultat: resultat,
        nombreArrives: _resultatController.resultats
            .where((r) => r.estArrive)
            .length,
      ),
    );
    if (correction == null || !mounted || _manche.id != mancheId) return;
    final edition = await _resultatController.corrigerResultat(
      manche: _manche,
      athlete: athlete,
      resultat: resultat,
      statut: correction.statut,
      mode: correction.mode,
      position: correction.position,
      tempsMillisecondes: correction.tempsMillisecondes,
      commentaire: correction.commentaire,
      accepterDepublication: correction.accepterDepublication,
    );
    if (!mounted) return;
    if (edition == null) {
      _afficherErreur(
        _resultatController.erreur ?? 'La correction n’a pas été confirmée.',
      );
      return;
    }
    setState(
      () => _manche = _manche.copierAvec(
        revisionResultats: edition.revision,
        resultatsPublies: false,
      ),
    );
    _mancheController.remplacerLocalement(_manche);
    _afficherMessage(
      edition.depublies
          ? 'Classement corrigé et retiré de la publication. Vérifie-le puis publie-le à nouveau.'
          : 'Résultat enregistré. Places, points et écarts recalculés.',
    );
  }

  Future<void> _publier() async {
    if (_operationEnCours) return;
    final publiee = await _mancheController.publierResultats(_manche);
    if (!mounted) return;
    if (publiee == null) {
      _afficherErreur(
        _mancheController.erreur ??
            'Publication impossible. Actualise la manche.',
      );
    } else {
      setState(() => _manche = publiee);
      _afficherMessage('Classement publié.');
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
    return _clotureEnCours ||
        _chargementDonnees ||
        _resultatController.operationEnCours ||
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
                key: ValueKey(_manche.id),
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
                    label: Text(
                      _clotureEnCours
                          ? 'Clôture en cours…'
                          : 'Réessayer la clôture',
                    ),
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
    if (!mounted || !_manche.estEnCours || _clotureEnCours) {
      return;
    }

    setState(() {
      _delaiSignaleCommeEcoule = true;
    });

    _clotureDemandee = true;
    if (!_operationEnCours) {
      _cloturerDelai();
    }
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
                        active:
                            _manche.estEnCours &&
                            !_delaiEcoule &&
                            !_operationEnCours,
                        onTap: () => _enregistrerArrivee(inscription.athlete),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          const SizedBox(height: 24),
          if (_manche.estTerminee) ...[
            OutlinedButton.icon(
              onPressed: _operationEnCours ? null : _saisirManuellement,
              icon: const Icon(Icons.edit_note),
              label: const Text('Saisir un résultat manuel'),
            ),
            Text(
              _manche.resultatsPublies ? 'Classement publié.' : 'Classement non publié : vérifie les résultats avant publication.',
            ),
            if (!_manche.resultatsPublies)
              FilledButton.icon(
                onPressed: _operationEnCours ? null : _publier,
                icon: const Icon(Icons.publish),
                label: const Text('Publier le classement'),
              ),
          ] else
            const Text(
              'La saisie manuelle et les corrections sont disponibles une fois la manche terminée.',
            ),
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
                  onCorriger: _manche.estTerminee && !_operationEnCours
                      ? () => _editerResultat(
                          resultat.athlete,
                          resultat: resultat,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
