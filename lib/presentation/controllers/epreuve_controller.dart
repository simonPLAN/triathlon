import 'package:flutter/foundation.dart';

import '../../application/use_cases/epreuve/creer_epreuve.dart';
import '../../application/use_cases/epreuve/lister_epreuves.dart';
import '../../domain/entities/epreuve.dart';
import '../../domain/entities/type_discipline.dart';

class EpreuveController extends ChangeNotifier {
  EpreuveController(this._creerEpreuve, this._listerEpreuves);

  final CreerEpreuve _creerEpreuve;
  final ListerEpreuves _listerEpreuves;

  List<Epreuve> _epreuves = const [];

  bool _chargement = false;
  bool _creationEnCours = false;
  String? _erreur;
  String? _competitionChargeeId;

  List<Epreuve> get epreuves {
    return List.unmodifiable(_epreuves);
  }

  bool get chargement => _chargement;

  bool get creationEnCours => _creationEnCours;

  String? get erreur => _erreur;

  bool get estVide => _epreuves.isEmpty;

  bool get aUneErreur => _erreur != null;

  Future<void> charger(String competitionId) async {
    if (_chargement) {
      return;
    }

    final idNettoye = competitionId.trim();

    if (idNettoye.isEmpty) {
      _erreur = 'L’identifiant de la compétition est obligatoire.';
      notifyListeners();
      return;
    }

    if (_competitionChargeeId != null && _competitionChargeeId != idNettoye) {
      _epreuves = const [];
    }

    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _epreuves = await _listerEpreuves.executer(idNettoye);

      _competitionChargeeId = idNettoye;
      _trierEpreuves();
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<Epreuve?> creer({
    required String competitionId,
    required TypeDiscipline discipline,
    required String nom,
    required int distanceMetres,
    required int nombreManches,
    required int ordre,
    required int dureeLimiteSecondes,
  }) async {
    if (_creationEnCours) {
      return null;
    }

    _creationEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final nouvelleEpreuve = await _creerEpreuve.executer(
        competitionId: competitionId,
        discipline: discipline,
        nom: nom,
        distanceMetres: distanceMetres,
        nombreManches: nombreManches,
        ordre: ordre,
        dureeLimiteSecondes: dureeLimiteSecondes,
      );

      _epreuves = [..._epreuves, nouvelleEpreuve];

      _competitionChargeeId = competitionId;
      _trierEpreuves();

      return nouvelleEpreuve;
    } on ArgumentError catch (exception) {
      _erreur =
          exception.message?.toString() ??
          'Les informations de l’épreuve '
              'sont invalides.';

      return null;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _creationEnCours = false;
      notifyListeners();
    }
  }

  Future<void> recharger() async {
    final competitionId = _competitionChargeeId;

    if (competitionId == null) {
      return;
    }

    await charger(competitionId);
  }

  int prochainOrdre() {
    if (_epreuves.isEmpty) {
      return 1;
    }

    final ordreMaximum = _epreuves
        .map((epreuve) => epreuve.ordre)
        .reduce((ordreA, ordreB) => ordreA > ordreB ? ordreA : ordreB);

    return ordreMaximum + 1;
  }

  void effacerErreur() {
    if (_erreur == null) {
      return;
    }

    _erreur = null;
    notifyListeners();
  }

  void reinitialiser() {
    _epreuves = const [];
    _chargement = false;
    _creationEnCours = false;
    _erreur = null;
    _competitionChargeeId = null;

    notifyListeners();
  }

  void _trierEpreuves() {
    final listeTriee = [..._epreuves];

    listeTriee.sort((epreuveA, epreuveB) {
      final comparaisonOrdre = epreuveA.ordre.compareTo(epreuveB.ordre);

      if (comparaisonOrdre != 0) {
        return comparaisonOrdre;
      }

      return epreuveA.nom.toLowerCase().compareTo(epreuveB.nom.toLowerCase());
    });

    _epreuves = listeTriee;
  }

  String _extraireMessageErreur(Object exception) {
    return exception
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}
