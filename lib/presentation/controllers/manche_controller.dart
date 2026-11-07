import 'package:flutter/foundation.dart';

import '../../application/use_cases/manche/annuler_manche.dart';
import '../../application/use_cases/manche/demarrer_manche.dart';
import '../../application/use_cases/manche/enregistrer_premiere_arrivee.dart';
import '../../application/use_cases/manche/generer_manches_pour_epreuve.dart';
import '../../application/use_cases/manche/lister_manches.dart';
import '../../application/use_cases/manche/publier_resultats_manche.dart';
import '../../application/use_cases/manche/terminer_manche.dart';
import '../../domain/entities/epreuve.dart';
import '../../domain/entities/manche.dart';
import '../../domain/ports/configuration_manche_repository.dart';
import '../../domain/ports/cycle_manche_repository.dart';
import '../../domain/entities/statut_resultat.dart';
import '../../application/use_cases/manche/configurer_manche.dart';

class MancheController extends ChangeNotifier {
  MancheController(
    this._genererManches,
    this._listerManches,
    this._demarrerManche,
    this._enregistrerPremiereArrivee,
    this._terminerManche,
    this._annulerManche,
    this._publierResultatsManche, {
    this.configurationRepository,
  });

  final ConfigurationMancheRepository? configurationRepository;
  bool get cycleAtomiqueDisponible =>
      configurationRepository is CycleMancheRepository;

  Future<Manche?> validerResultats(Manche manche) {
    final repository = configurationRepository;
    if (repository is! CycleMancheRepository) return Future.value(null);
    return _executerAction(
      () => (repository as CycleMancheRepository).validerResultats(
        manche.id,
        manche.revisionResultats,
      ),
    );
  }

  Future<Manche?> cloturerDelaiAtomique(Manche manche) {
    final repository = configurationRepository;
    if (repository is! CycleMancheRepository) return Future.value(null);
    return _executerAction(
      () => (repository as CycleMancheRepository).cloturerDelai(manche.id),
    );
  }

  Future<Manche?> declarerStatut({
    required Manche manche,
    required String athleteId,
    required StatutResultat statut,
    required String motif,
  }) {
    final repository = configurationRepository;
    if (repository is! CycleMancheRepository) return Future.value(null);
    return _executerAction(() async {
      if (statut != StatutResultat.abandon &&
          statut != StatutResultat.disqualifie) {
        throw ArgumentError('Choisis abandon ou disqualification.');
      }
      if (motif.trim().isEmpty) {
        throw ArgumentError('Le motif est obligatoire.');
      }
      await (repository as CycleMancheRepository).declarerStatut(
        mancheId: manche.id,
        athleteId: athleteId,
        statut: statut,
        motif: motif.trim(),
      );
      return manche;
    });
  }

  Future<Manche?> configurer({
    required Manche manche,
    required List<String> athleteIds,
    required int dureeLimiteSecondes,
  }) {
    final repository = configurationRepository;
    if (repository == null) {
      _erreur = 'La configuration des participants n’est pas disponible.';
      notifyListeners();
      return Future.value(null);
    }
    return _executerAction(
      () => ConfigurerManche(repository).executer(
        manche: manche,
        athleteIds: athleteIds,
        dureeLimiteSecondes: dureeLimiteSecondes,
      ),
    );
  }

  Future<Manche?> demarrerSuivanteAutomatiquement(Manche mancheTerminee) async {
    final suivantes =
        _manches
            .where(
              (manche) =>
                  manche.epreuveId == mancheTerminee.epreuveId &&
                  manche.numero > mancheTerminee.numero &&
                  manche.estAVenir,
            )
            .toList()
          ..sort((a, b) => a.numero.compareTo(b.numero));

    if (suivantes.isEmpty) {
      return null;
    }

    var suivante = suivantes.first;
    if (!suivante.participantsDefinis) {
      if (mancheTerminee.participantsAthleteIds.isEmpty ||
          mancheTerminee.dureeLimiteSecondes == null) {
        _erreur =
            'La manche suivante ne peut pas reprendre une configuration vide.';
        notifyListeners();
        return null;
      }
      final configuree = await configurer(
        manche: suivante,
        athleteIds: mancheTerminee.participantsAthleteIds,
        dureeLimiteSecondes: mancheTerminee.dureeLimiteSecondes!,
      );
      if (configuree == null) {
        return null;
      }
      suivante = configuree;
    }

    return demarrer(suivante);
  }

  final GenererManchesPourEpreuve _genererManches;
  final ListerManches _listerManches;
  final DemarrerManche _demarrerManche;
  final EnregistrerPremiereArrivee _enregistrerPremiereArrivee;
  final TerminerManche _terminerManche;
  final AnnulerManche _annulerManche;
  final PublierResultatsManche _publierResultatsManche;

  List<Manche> _manches = const [];

  bool _chargement = false;
  bool _generationEnCours = false;
  bool _actionEnCours = false;
  String? _erreur;
  String? _epreuveChargeeId;

  List<Manche> get manches {
    return List.unmodifiable(_manches);
  }

  bool get chargement => _chargement;

  bool get generationEnCours => _generationEnCours;

  bool get actionEnCours => _actionEnCours;

  String? get erreur => _erreur;

  Future<void> charger(String epreuveId) async {
    if (_chargement) {
      return;
    }

    final idNettoye = epreuveId.trim();

    if (idNettoye.isEmpty) {
      _erreur = 'L’identifiant de l’épreuve est obligatoire.';
      notifyListeners();
      return;
    }

    if (_epreuveChargeeId != null && _epreuveChargeeId != idNettoye) {
      _manches = const [];
    }

    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _manches = await _listerManches.executer(idNettoye);

      _epreuveChargeeId = idNettoye;
      _trierManches();
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<List<Manche>?> generer(Epreuve epreuve) async {
    if (_generationEnCours) {
      return null;
    }

    _generationEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final manches = await _genererManches.executer(epreuve);

      _manches = manches;
      _epreuveChargeeId = epreuve.id;
      _trierManches();

      return List.unmodifiable(_manches);
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _generationEnCours = false;
      notifyListeners();
    }
  }

  Future<Manche?> demarrer(Manche manche) {
    final autreMancheEnCours = _manches.any(
      (element) => element.id != manche.id && element.estEnCours,
    );

    if (autreMancheEnCours) {
      _erreur = 'Une autre manche de cette épreuve est déjà en cours.';
      notifyListeners();
      return Future.value(null);
    }

    final manchePrecedenteNonTerminee = _manches.any(
      (element) =>
          element.numero < manche.numero &&
          !element.estTerminee &&
          !element.estAnnulee,
    );

    if (manchePrecedenteNonTerminee) {
      _erreur =
          'Les manches précédentes doivent être terminées '
          'ou annulées avant de démarrer celle-ci.';
      notifyListeners();
      return Future.value(null);
    }

    return _executerAction(() => _demarrerManche.executer(manche));
  }

  Future<Manche?> enregistrerPremiereArrivee({
    required Manche manche,
    required int dureeLimiteSecondes,
  }) {
    return _executerAction(
      () => _enregistrerPremiereArrivee.executer(
        manche: manche,
        dureeLimiteSecondes: dureeLimiteSecondes,
      ),
    );
  }

  Future<Manche?> terminer(Manche manche) {
    return _executerAction(() => _terminerManche.executer(manche));
  }

  Future<Manche?> annuler(Manche manche) {
    return _executerAction(() => _annulerManche.executer(manche));
  }

  Future<Manche?> publierResultats(Manche manche) {
    return _executerAction(() => _publierResultatsManche.executer(manche));
  }

  Future<int?> publierTousLesResultats() async {
    if (_actionEnCours || _chargement || _generationEnCours) return null;

    final aPublier = _manches.where((m) => m.peutPublierResultats).toList();
    if (aPublier.isEmpty) return 0;

    _actionEnCours = true;
    _erreur = null;
    notifyListeners();
    var nombrePublie = 0;
    try {
      for (final manche in aPublier) {
        final publiee = await _publierResultatsManche.executer(manche);
        remplacerLocalement(publiee);
        nombrePublie++;
      }
      return nombrePublie;
    } catch (exception) {
      _erreur =
          '$nombrePublie manche(s) publiée(s). '
          'Publication interrompue : ${_extraireMessageErreur(exception)} '
          'Réessaie pour publier les manches restantes.';
      return null;
    } finally {
      _actionEnCours = false;
      notifyListeners();
    }
  }

  Future<Manche?> _executerAction(Future<Manche> Function() action) async {
    if (_actionEnCours) {
      return null;
    }

    _actionEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final mancheActualisee = await action();

      remplacerLocalement(mancheActualisee);

      return mancheActualisee;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _actionEnCours = false;
      notifyListeners();
    }
  }

  void remplacerLocalement(Manche manche) {
    final index = _manches.indexWhere((element) => element.id == manche.id);

    if (index < 0) {
      _manches = [..._manches, manche];
    } else {
      final nouvelleListe = [..._manches];
      nouvelleListe[index] = manche;
      _manches = nouvelleListe;
    }

    _trierManches();
    notifyListeners();
  }

  void effacerErreur() {
    if (_erreur == null) {
      return;
    }

    _erreur = null;
    notifyListeners();
  }

  void reinitialiser() {
    _manches = const [];
    _chargement = false;
    _generationEnCours = false;
    _actionEnCours = false;
    _erreur = null;
    _epreuveChargeeId = null;

    notifyListeners();
  }

  void _trierManches() {
    final manchesTriees = [..._manches]
      ..sort((mancheA, mancheB) {
        return mancheA.numero.compareTo(mancheB.numero);
      });

    _manches = manchesTriees;
  }

  String _extraireMessageErreur(Object exception) {
    return exception
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}
