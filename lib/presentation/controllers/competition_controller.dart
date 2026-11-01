import 'package:flutter/foundation.dart';

import '../../application/use_cases/competition/creer_competition.dart';
import '../../application/use_cases/competition/lister_competitions.dart';
import '../../domain/entities/competition.dart';

class CompetitionController extends ChangeNotifier {
  CompetitionController({
    required this._creerCompetition,
    required this._listerCompetitions,
  });

  final CreerCompetition _creerCompetition;
  final ListerCompetitions _listerCompetitions;

  List<Competition> _competitions = const [];

  bool _chargement = false;
  bool _creationEnCours = false;
  String? _erreur;

  List<Competition> get competitions {
    return List.unmodifiable(_competitions);
  }

  bool get chargement => _chargement;

  bool get creationEnCours => _creationEnCours;

  String? get erreur => _erreur;

  bool get estVide => _competitions.isEmpty;

  bool get aUneErreur => _erreur != null;

  Future<void> charger() async {
    if (_chargement) {
      return;
    }

    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _competitions = await _listerCompetitions.executer();
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<bool> creer({
    required String nom,
    required DateTime dateCompetition,
    required String coachId,
    String? description,
    String? lieu,
  }) async {
    if (_creationEnCours) {
      return false;
    }

    _creationEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final nouvelleCompetition = await _creerCompetition.executer(
        nom: nom,
        dateCompetition: dateCompetition,
        coachId: coachId,
        description: description,
        lieu: lieu,
      );

      _competitions = [..._competitions, nouvelleCompetition];

      _trierCompetitions();

      return true;
    } on ArgumentError catch (exception) {
      _erreur =
          exception.message?.toString() ??
          'Les informations saisies sont invalides.';

      return false;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);

      return false;
    } finally {
      _creationEnCours = false;
      notifyListeners();
    }
  }

  Future<void> recharger() {
    return charger();
  }

  void effacerErreur() {
    if (_erreur == null) {
      return;
    }

    _erreur = null;
    notifyListeners();
  }

  void _trierCompetitions() {
    final competitionsTriees = [..._competitions];

    competitionsTriees.sort((competitionA, competitionB) {
      final comparaisonDate = competitionA.dateCompetition.compareTo(
        competitionB.dateCompetition,
      );

      if (comparaisonDate != 0) {
        return comparaisonDate;
      }

      return competitionA.nom.toLowerCase().compareTo(
        competitionB.nom.toLowerCase(),
      );
    });

    _competitions = competitionsTriees;
  }

  String _extraireMessageErreur(Object exception) {
    return exception
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }

  void reinitialiser() {
    _competitions = const [];
    _chargement = false;
    _creationEnCours = false;
    _erreur = null;
    notifyListeners();
  }
}
