import 'package:flutter/foundation.dart';

import '../../application/use_cases/competition/changer_statut_competition.dart';
import '../../application/use_cases/competition/creer_competition.dart';
import '../../application/use_cases/competition/lister_competitions.dart';
import '../../application/use_cases/competition/modifier_competition.dart';
import '../../application/use_cases/competition/supprimer_competition.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/statut_competition.dart';

class CompetitionController extends ChangeNotifier {
  CompetitionController(
    this._creerCompetition,
    this._listerCompetitions,
    this._modifierCompetition,
    this._changerStatutCompetition,
    this._supprimerCompetition,
  );

  final CreerCompetition _creerCompetition;
  final ListerCompetitions _listerCompetitions;
  final ModifierCompetition _modifierCompetition;
  List<Competition> _competitions = const [];
  final ChangerStatutCompetition _changerStatutCompetition;
  bool _chargement = false;
  bool _creationEnCours = false;
  bool _modificationEnCours = false;
  String? _erreur;
  bool _changementStatutEnCours = false;
  final SupprimerCompetition _supprimerCompetition;

  List<Competition> get competitions {
    return List.unmodifiable(_competitions);
  }

  bool _suppressionEnCours = false;

  bool get modificationEnCours {
    return _modificationEnCours;
  }

  bool get suppressionEnCours {
    return _suppressionEnCours;
  }

  bool get changementStatutEnCours {
    return _changementStatutEnCours;
  }

  bool get chargement => _chargement;

  bool get creationEnCours => _creationEnCours;

  String? get erreur => _erreur;

  bool get estVide => _competitions.isEmpty;

  bool get aUneErreur => _erreur != null;

  Future<bool> supprimer(Competition competition) async {
    if (_suppressionEnCours) {
      return false;
    }

    _suppressionEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      await _supprimerCompetition.executer(competition);

      _competitions = _competitions
          .where((element) => element.id != competition.id)
          .toList(growable: false);

      return true;
    } on ArgumentError catch (exception) {
      _erreur =
          exception.message?.toString() ??
          'La compétition ne peut pas être supprimée.';

      return false;
    } on StateError catch (exception) {
      _erreur = _extraireMessageErreur(exception);

      return false;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);

      return false;
    } finally {
      _suppressionEnCours = false;
      notifyListeners();
    }
  }

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
    bool demarrageAutomatiqueMancheSuivante = false,
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
        demarrageAutomatiqueMancheSuivante: demarrageAutomatiqueMancheSuivante,
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
    _modificationEnCours = false;
    _changementStatutEnCours = false;
    _erreur = null;
    _suppressionEnCours = false;
    notifyListeners();
  }

  void _remplacerCompetitionDansListe(Competition competition) {
    final index = _competitions.indexWhere(
      (element) => element.id == competition.id,
    );

    if (index < 0) {
      _competitions = [..._competitions, competition];

      _trierCompetitions();
      return;
    }

    final nouvelleListe = [..._competitions];

    nouvelleListe[index] = competition;
    _competitions = nouvelleListe;

    _trierCompetitions();
  }

  Future<Competition?> modifier({
    required Competition competition,
    required String nom,
    required DateTime dateCompetition,
    required bool demarrageAutomatiqueMancheSuivante,
    String? description,
    String? lieu,
  }) async {
    if (_modificationEnCours) {
      return null;
    }

    _modificationEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final competitionModifiee = await _modifierCompetition.executer(
        competition: competition,
        nom: nom,
        description: description,
        lieu: lieu,
        dateCompetition: dateCompetition,
        demarrageAutomatiqueMancheSuivante: demarrageAutomatiqueMancheSuivante,
      );

      final index = _competitions.indexWhere(
        (element) => element.id == competitionModifiee.id,
      );

      if (index >= 0) {
        final nouvelleListe = [..._competitions];

        nouvelleListe[index] = competitionModifiee;
        _competitions = nouvelleListe;
      } else {
        _competitions = [..._competitions, competitionModifiee];
      }

      _trierCompetitions();

      return competitionModifiee;
    } on ArgumentError catch (exception) {
      _erreur =
          exception.message?.toString() ??
          'Les informations saisies sont invalides.';

      return null;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);

      return null;
    } finally {
      _modificationEnCours = false;
      notifyListeners();
    }
  }

  Future<Competition?> changerStatut({
    required Competition competition,
    required StatutCompetition nouveauStatut,
  }) async {
    if (_changementStatutEnCours) {
      return null;
    }

    _changementStatutEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final competitionActualisee = await _changerStatutCompetition.executer(
        competition: competition,
        nouveauStatut: nouveauStatut,
      );

      _remplacerCompetitionDansListe(competitionActualisee);

      return competitionActualisee;
    } on ArgumentError catch (exception) {
      _erreur =
          exception.message?.toString() ??
          'Le changement de statut est invalide.';

      return null;
    } on StateError catch (exception) {
      _erreur = _extraireMessageErreur(exception);

      return null;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);

      return null;
    } finally {
      _changementStatutEnCours = false;
      notifyListeners();
    }
  }
}
