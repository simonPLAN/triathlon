import 'package:flutter/foundation.dart';

import '../../application/use_cases/auth/recuperer_compte.dart';

enum EtapeRecuperation {
  inactive,
  verification,
  nouveauMotDePasse,
  erreur,
  succes,
}

class RecuperationCompteController extends ChangeNotifier {
  RecuperationCompteController(this._recuperer);
  final RecupererCompte _recuperer;

  EtapeRecuperation _etape = EtapeRecuperation.inactive;
  bool _operation = false;
  bool _envoi = false;
  bool _detruit = false;
  Uri? _lienEnCours;
  String? _erreur;

  EtapeRecuperation get etape => _etape;
  bool get active => _etape != EtapeRecuperation.inactive;
  bool get operationEnCours => _operation;
  bool get envoiEnCours => _envoi;
  String? get erreur => _erreur;

  void _actualiser() {
    if (!_detruit) notifyListeners();
  }

  Future<void> envoyerLien(String email) async {
    if (_envoi) {
      throw StateError(
        'Une demande de lien est déjà en cours. Patiente quelques instants.',
      );
    }
    _envoi = true;
    _actualiser();
    try {
      await _recuperer.envoyerLien(email);
    } finally {
      _envoi = false;
      _actualiser();
    }
  }

  Future<void> traiterLien(Uri lien) async {
    if (!_recuperer.liens.correspond(lien) || _operation) return;
    if (_lienEnCours == lien && active) return;
    _lienEnCours = lien;
    _etape = EtapeRecuperation.verification;
    _operation = true;
    _erreur = null;
    _actualiser();
    try {
      await _recuperer.verifierLien(lien);
      _etape = EtapeRecuperation.nouveauMotDePasse;
    } catch (e) {
      _etape = EtapeRecuperation.erreur;
      _erreur = _message(e);
    } finally {
      _operation = false;
      _actualiser();
    }
  }

  Future<void> enregistrer(String motDePasse, String confirmation) async {
    if (_operation || _etape != EtapeRecuperation.nouveauMotDePasse) return;
    _operation = true;
    _erreur = null;
    _actualiser();
    try {
      await _recuperer.changerMotDePasse(motDePasse, confirmation);
      _etape = EtapeRecuperation.succes;
    } catch (e) {
      _erreur = _message(e);
    } finally {
      _operation = false;
      _actualiser();
    }
  }

  Future<void> fermer() async {
    if (_operation) return;
    _operation = true;
    _actualiser();
    try {
      await _recuperer.terminer();
      _etape = EtapeRecuperation.inactive;
      _lienEnCours = null;
      _erreur = null;
    } catch (e) {
      _erreur = _message(e);
    } finally {
      _operation = false;
      _actualiser();
    }
  }

  String _message(Object e) => e
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _detruit = true;
    super.dispose();
  }
}
