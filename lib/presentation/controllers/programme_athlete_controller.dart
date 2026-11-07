import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/programme_competition.dart';

class ProgrammeAthleteController extends ChangeNotifier {
  ProgrammeAthleteController(this._lire);
  final Future<ProgrammeCompetition> Function() _lire;
  ProgrammeCompetition? programme;
  String? erreur;
  bool chargement = false;
  bool _detruit = false;
  Future<void>? _requete;

  Future<void> recharger() {
    if (_requete != null) return _requete!;
    if (_detruit) return Future.value();
    final completion = Completer<void>();
    _requete = completion.future;
    unawaited(_charger(completion));
    return completion.future;
  }

  Future<void> _charger(Completer<void> completion) async {
    chargement = true;
    erreur = null;
    _notifier();
    try {
      final donnees = await _lire().timeout(const Duration(seconds: 20));
      if (!_detruit) programme = donnees;
    } catch (e) {
      if (!_detruit) {
        programme = null;
        erreur = e is StateError ? e.message.toString() : 'Impossible d’actualiser le programme. Vérifie ta connexion puis réessaie.';
      }
    } finally {
      _requete = null;
      chargement = false;
      _notifier();
      completion.complete();
    }
  }

  void _notifier() {
    if (!_detruit) notifyListeners();
  }

  @override
  void dispose() {
    _detruit = true;
    super.dispose();
  }
}
