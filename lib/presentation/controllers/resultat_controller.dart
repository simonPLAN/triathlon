import 'package:flutter/foundation.dart';

import '../../application/use_cases/resultat/enregistrer_arrivee.dart';
import '../../application/use_cases/resultat/corriger_resultat.dart';
import '../../domain/entities/statut_resultat.dart';
import '../../application/use_cases/resultat/lister_resultats_manche.dart';
import '../../application/use_cases/resultat/marquer_athletes_hors_delai.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/entities/manche.dart';
import '../../domain/entities/resultat.dart';

class ResultatController extends ChangeNotifier {
  ResultatController(
    this._listerResultatsManche,
    this._enregistrerArrivee,
    this._corrigerResultat,
    this._marquerAthletesHorsDelai,
  );

  final ListerResultatsManche _listerResultatsManche;
  final EnregistrerArrivee _enregistrerArrivee;
  final CorrigerResultat _corrigerResultat;
  final MarquerAthletesHorsDelai _marquerAthletesHorsDelai;
  bool _marquageHorsDelaiEnCours = false;
  List<Resultat> _resultats = const [];

  bool get marquageHorsDelaiEnCours {
    return _marquageHorsDelaiEnCours;
  }

  bool get operationEnCours {
    return _chargement || _enregistrementEnCours || _marquageHorsDelaiEnCours;
  }

  String? _mancheChargeeId;
  String? _erreur;

  bool _chargement = false;
  bool _enregistrementEnCours = false;

  List<Resultat> get resultats {
    return List.unmodifiable(_resultats);
  }

  bool get chargement => _chargement;

  bool get enregistrementEnCours {
    return _enregistrementEnCours;
  }

  bool get estVide => _resultats.isEmpty;

  String? get erreur => _erreur;

  Future<void> charger(String mancheId) async {
    if (_chargement) {
      return;
    }

    final idNettoye = mancheId.trim();

    if (idNettoye.isEmpty) {
      _erreur = 'L’identifiant de la manche est obligatoire.';
      notifyListeners();
      return;
    }

    if (_mancheChargeeId != null && _mancheChargeeId != idNettoye) {
      _resultats = const [];
    }

    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _resultats = await _listerResultatsManche.executer(idNettoye);

      _mancheChargeeId = idNettoye;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<List<Resultat>?> marquerHorsDelai({
    required Manche manche,
    required List<Athlete> athletes,
  }) async {
    if (_marquageHorsDelaiEnCours) {
      return null;
    }

    _marquageHorsDelaiEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final nouveauxResultats = await _marquerAthletesHorsDelai.executer(
        manche: manche,
        athletes: athletes,
      );

      if (nouveauxResultats.isNotEmpty) {
        final idsExistants = _resultats.map((resultat) => resultat.id).toSet();

        _resultats = [
          ..._resultats,
          ...nouveauxResultats.where((resultat) {
            return !idsExistants.contains(resultat.id);
          }),
        ];

        _trierResultats();
      }

      return List.unmodifiable(nouveauxResultats);
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _marquageHorsDelaiEnCours = false;
      notifyListeners();
    }
  }

  Future<Resultat?> enregistrerArrivee({
    required Manche manche,
    required Athlete athlete,
  }) async {
    if (_enregistrementEnCours) {
      return null;
    }

    final resultatDejaPresent = _resultats.any(
      (resultat) => resultat.athlete.id == athlete.id,
    );

    if (resultatDejaPresent) {
      _erreur = 'Un résultat existe déjà pour cet athlète.';
      notifyListeners();
      return null;
    }

    _enregistrementEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final resultat = await _enregistrerArrivee.executer(
        manche: manche,
        athlete: athlete,
      );

      _resultats = [..._resultats, resultat];

      _trierResultats();

      return resultat;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _enregistrementEnCours = false;
      notifyListeners();
    }
  }

  Future<Resultat?> corrigerResultat({
    required Resultat resultat,
    required StatutResultat statut,
    int? position,
    String? commentaire,
  }) async {
    if (_enregistrementEnCours) {
      return null;
    }

    if (statut == StatutResultat.arrive &&
        position != null &&
        _resultats.any(
          (element) =>
              element.id != resultat.id && element.position == position,
        )) {
      _erreur = 'Cette position est déjà utilisée par un autre athlète.';
      notifyListeners();
      return null;
    }

    _enregistrementEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final corrige = await _corrigerResultat.executer(
        resultat: resultat,
        statut: statut,
        position: position,
        commentaire: commentaire,
      );
      remplacerLocalement(corrige);
      return corrige;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _enregistrementEnCours = false;
      notifyListeners();
    }
  }

  bool possedeResultatPour(String athleteId) {
    return _resultats.any((resultat) => resultat.athlete.id == athleteId);
  }

  Resultat? resultatPour(String athleteId) {
    for (final resultat in _resultats) {
      if (resultat.athlete.id == athleteId) {
        return resultat;
      }
    }

    return null;
  }

  Future<void> recharger() async {
    final mancheId = _mancheChargeeId;

    if (mancheId == null) {
      return;
    }

    await charger(mancheId);
  }

  void remplacerLocalement(Resultat resultat) {
    final index = _resultats.indexWhere((element) => element.id == resultat.id);

    if (index < 0) {
      _resultats = [..._resultats, resultat];
    } else {
      final nouvelleListe = [..._resultats];

      nouvelleListe[index] = resultat;
      _resultats = nouvelleListe;
    }

    _trierResultats();
    notifyListeners();
  }

  void supprimerLocalement(String resultatId) {
    _resultats = _resultats
        .where((resultat) => resultat.id != resultatId)
        .toList(growable: false);

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
    _resultats = const [];
    _mancheChargeeId = null;
    _erreur = null;
    _chargement = false;
    _enregistrementEnCours = false;
    _marquageHorsDelaiEnCours = false;

    notifyListeners();
  }

  void _trierResultats() {
    final listeTriee = [..._resultats];

    listeTriee.sort((resultatA, resultatB) {
      final positionA = resultatA.position;
      final positionB = resultatB.position;

      if (positionA != null && positionB == null) {
        return -1;
      }

      if (positionA == null && positionB != null) {
        return 1;
      }

      if (positionA != null && positionB != null) {
        final comparaison = positionA.compareTo(positionB);

        if (comparaison != 0) {
          return comparaison;
        }
      }

      return resultatA.athlete.nomComplet.toLowerCase().compareTo(
        resultatB.athlete.nomComplet.toLowerCase(),
      );
    });

    _resultats = listeTriee;
  }

  String _extraireMessageErreur(Object exception) {
    return exception
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}
