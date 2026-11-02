import 'package:flutter/foundation.dart';

import '../../application/use_cases/competition/consulter_programme_competition.dart';
import '../../domain/entities/programme_competition.dart';

import '../../application/use_cases/competition/suivre_competitions_athlete.dart';
import '../../domain/entities/resultat_publie.dart';

import '../../application/use_cases/competition/lister_competitions_ouvertes.dart';
import '../../domain/entities/competition.dart';

class CompetitionsOuvertesController extends ChangeNotifier {
  CompetitionsOuvertesController(
    this._listerCompetitionsOuvertes,
    this._suivi, {
    this._programme,
  });

  final ConsulterProgrammeCompetition? _programme;

  Future<ProgrammeCompetition> programmeCompetition(String competitionId) {
    final programme = _programme;
    if (programme == null) {
      throw StateError('Le programme n’est pas disponible.');
    }
    return programme.executer(competitionId);
  }

  final SuivreCompetitionsAthlete _suivi;
  List<Competition> _inscrites = const [];
  List<Competition> get inscrites => List.unmodifiable(_inscrites);
  String? erreurInscriptions;

  Future<List<ResultatPublie>> resultatsPublies(String competitionId) =>
      _suivi.resultatsPublies(competitionId);

  final ListerCompetitionsOuvertes _listerCompetitionsOuvertes;

  List<Competition> _competitions = const [];

  bool _chargement = false;
  String? _erreur;

  List<Competition> get competitions {
    return List.unmodifiable(_competitions);
  }

  bool get chargement => _chargement;

  String? get erreur => _erreur;

  bool get estVide => _competitions.isEmpty;

  Future<void> charger() async {
    if (_chargement) {
      return;
    }

    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _competitions = await _listerCompetitionsOuvertes.executer();

      _trierCompetitions();
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
    }
    erreurInscriptions = null;
    try {
      _inscrites = await _suivi.listerInscriptions();
    } catch (exception) {
      erreurInscriptions = _extraireMessageErreur(exception);
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<void> recharger() {
    return charger();
  }

  void actualiserInscription(
    Competition competition, {
    required bool inscrite,
  }) {
    _inscrites = _inscrites.where((c) => c.id != competition.id).toList();
    if (inscrite) _inscrites = [..._inscrites, competition];
    notifyListeners();
  }

  void retirerCompetition(String competitionId) {
    _competitions = _competitions
        .where((competition) => competition.id != competitionId)
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
    _competitions = const [];
    _inscrites = const [];
    erreurInscriptions = null;
    _chargement = false;
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
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}
