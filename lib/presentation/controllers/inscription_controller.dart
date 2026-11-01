import 'package:flutter/foundation.dart';

import '../../application/use_cases/inscription/desinscrire_athlete_competition.dart';
import '../../application/use_cases/inscription/inscrire_athlete_competition.dart';
import '../../application/use_cases/inscription/inscrire_utilisateur_connecte.dart';
import '../../application/use_cases/inscription/lister_inscriptions.dart';
import '../../application/use_cases/inscription/modifier_dossard_inscription.dart';
import '../../application/use_cases/inscription/obtenir_inscription_utilisateur_connecte.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/inscription.dart';

class InscriptionController extends ChangeNotifier {
  InscriptionController(
    this._listerInscriptions,
    this._inscrireAthleteCompetition,
    this._modifierDossardInscription,
    this._desinscrireAthleteCompetition,
    this._inscrireUtilisateurConnecte,
    this._obtenirInscriptionUtilisateurConnecte,
  );

  final ListerInscriptions _listerInscriptions;

  final InscrireAthleteCompetition _inscrireAthleteCompetition;

  final ModifierDossardInscription _modifierDossardInscription;

  final DesinscrireAthleteCompetition _desinscrireAthleteCompetition;
  final InscrireUtilisateurConnecte _inscrireUtilisateurConnecte;
  final ObtenirInscriptionUtilisateurConnecte
  _obtenirInscriptionUtilisateurConnecte;
  List<Inscription> _inscriptions = const [];
  final Map<String, Inscription?> _inscriptionsUtilisateur = {};

  final Set<String> _verificationsEnCours = {};
  String? _competitionId;
  String? _erreur;

  bool _chargement = false;
  bool _inscriptionEnCours = false;
  bool _modificationEnCours = false;
  bool _desinscriptionEnCours = false;

  List<Inscription> get inscriptions {
    return List.unmodifiable(_inscriptions);
  }

  String? get erreur => _erreur;

  bool get chargement => _chargement;

  bool get inscriptionEnCours {
    return _inscriptionEnCours;
  }

  Inscription? inscriptionUtilisateurPour(String competitionId) {
    return _inscriptionsUtilisateur[competitionId];
  }

  bool inscriptionUtilisateurVerifiee(String competitionId) {
    return _inscriptionsUtilisateur.containsKey(competitionId);
  }

  bool verificationEnCoursPour(String competitionId) {
    return _verificationsEnCours.contains(competitionId);
  }

  bool estInscritA(String competitionId) {
    return _inscriptionsUtilisateur[competitionId] != null;
  }

  bool get modificationEnCours {
    return _modificationEnCours;
  }

  bool get desinscriptionEnCours {
    return _desinscriptionEnCours;
  }

  Future<void> verifierInscriptionUtilisateur({
    required Competition competition,
  }) async {
    final competitionId = competition.id.trim();

    if (competitionId.isEmpty) {
      return;
    }

    if (_verificationsEnCours.contains(competitionId)) {
      return;
    }

    _verificationsEnCours.add(competitionId);
    notifyListeners();

    try {
      final inscription = await _obtenirInscriptionUtilisateurConnecte.executer(
        competition: competition,
      );

      _inscriptionsUtilisateur[competitionId] = inscription;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
    } finally {
      _verificationsEnCours.remove(competitionId);
      notifyListeners();
    }
  }

  bool get estVide => _inscriptions.isEmpty;

  Future<void> verifierInscriptionsUtilisateur(
    List<Competition> competitions,
  ) async {
    await Future.wait(
      competitions.map((competition) {
        return verifierInscriptionUtilisateur(competition: competition);
      }),
    );
  }

  bool get operationEnCours {
    return _chargement ||
        _inscriptionEnCours ||
        _modificationEnCours ||
        _desinscriptionEnCours;
  }

  Future<Inscription?> inscrireUtilisateurConnecte({
    required Competition competition,
  }) async {
    if (_inscriptionEnCours) {
      return null;
    }

    _inscriptionEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final nouvelleInscription = await _inscrireUtilisateurConnecte.executer(
        competition: competition,
      );

      _inscriptionsUtilisateur[competition.id] = nouvelleInscription;

      final inscriptionExistante = _inscriptions.any((inscription) {
        return inscription.id == nouvelleInscription.id ||
            inscription.athlete.id == nouvelleInscription.athlete.id;
      });

      if (!inscriptionExistante) {
        _inscriptions = [..._inscriptions, nouvelleInscription];

        _trierInscriptions();
      }

      return nouvelleInscription;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _inscriptionEnCours = false;
      notifyListeners();
    }
  }

  Future<void> charger({required String competitionId}) async {
    if (_chargement) {
      return;
    }

    final idNettoye = competitionId.trim();

    if (idNettoye.isEmpty) {
      _erreur = 'L’identifiant de la compétition est obligatoire.';
      notifyListeners();
      return;
    }

    _competitionId = idNettoye;
    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _inscriptions = await _listerInscriptions.executer(
        competitionId: idNettoye,
      );

      _trierInscriptions();
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<bool> inscrire({required String athleteId, int? numeroDossard}) async {
    if (_inscriptionEnCours) {
      return false;
    }

    final competitionId = _competitionId;

    if (competitionId == null || competitionId.isEmpty) {
      _erreur = 'Aucune compétition n’est sélectionnée.';
      notifyListeners();
      return false;
    }

    _inscriptionEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final nouvelleInscription = await _inscrireAthleteCompetition.executer(
        competitionId: competitionId,
        athleteId: athleteId,
        numeroDossard: numeroDossard,
      );

      _inscriptions = [..._inscriptions, nouvelleInscription];

      _trierInscriptions();

      return true;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return false;
    } finally {
      _inscriptionEnCours = false;
      notifyListeners();
    }
  }

  Future<Inscription?> modifierDossard({
    required Inscription inscription,
    int? numeroDossard,
  }) async {
    if (_modificationEnCours) {
      return null;
    }

    _modificationEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      final inscriptionActualisee = await _modifierDossardInscription.executer(
        inscriptionId: inscription.id,
        numeroDossard: numeroDossard,
      );

      _remplacerInscriptionDansListe(inscriptionActualisee);

      return inscriptionActualisee;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return null;
    } finally {
      _modificationEnCours = false;
      notifyListeners();
    }
  }

  Future<bool> desinscrire(Inscription inscription) async {
    if (_desinscriptionEnCours) {
      return false;
    }

    _desinscriptionEnCours = true;
    _erreur = null;
    notifyListeners();

    try {
      await _desinscrireAthleteCompetition.executer(inscription);

      _inscriptions = _inscriptions
          .where((element) => element.id != inscription.id)
          .toList(growable: false);

      _inscriptionsUtilisateur.remove(inscription.competitionId);

      return true;
    } catch (exception) {
      _erreur = _extraireMessageErreur(exception);
      return false;
    } finally {
      _desinscriptionEnCours = false;
      notifyListeners();
    }
  }

  void reinitialiserInscriptionsUtilisateur() {
    _inscriptionsUtilisateur.clear();
    _verificationsEnCours.clear();
    notifyListeners();
  }

  Future<void> recharger() async {
    final competitionId = _competitionId;

    if (competitionId == null) {
      return;
    }

    await charger(competitionId: competitionId);
  }

  void effacerErreur() {
    if (_erreur == null) {
      return;
    }

    _erreur = null;
    notifyListeners();
  }

  void reinitialiser() {
    _inscriptions = const [];

    _inscriptionsUtilisateur.clear();
    _verificationsEnCours.clear();

    _competitionId = null;
    _erreur = null;

    _chargement = false;
    _inscriptionEnCours = false;
    _modificationEnCours = false;
    _desinscriptionEnCours = false;

    notifyListeners();
  }

  void _remplacerInscriptionDansListe(Inscription inscription) {
    final index = _inscriptions.indexWhere(
      (element) => element.id == inscription.id,
    );

    if (index < 0) {
      _inscriptions = [..._inscriptions, inscription];
    } else {
      final nouvelleListe = [..._inscriptions];

      nouvelleListe[index] = inscription;
      _inscriptions = nouvelleListe;
    }

    _trierInscriptions();
  }

  void _trierInscriptions() {
    final listeTriee = [..._inscriptions];

    listeTriee.sort((inscriptionA, inscriptionB) {
      final dossardA = inscriptionA.numeroDossard;
      final dossardB = inscriptionB.numeroDossard;

      if (dossardA != null && dossardB != null) {
        final comparaisonDossard = dossardA.compareTo(dossardB);

        if (comparaisonDossard != 0) {
          return comparaisonDossard;
        }
      } else if (dossardA != null) {
        return -1;
      } else if (dossardB != null) {
        return 1;
      }

      return inscriptionA.athlete.nomComplet.toLowerCase().compareTo(
        inscriptionB.athlete.nomComplet.toLowerCase(),
      );
    });

    _inscriptions = listeTriee;
  }

  String _extraireMessageErreur(Object exception) {
    return exception
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}
