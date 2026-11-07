import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/resultat_publie.dart';

/// Source unique de l'écran : chaque actualisation remplace les résultats
/// et notifie immédiatement les deux vues, sans dépendre d'un changement d'onglet.
class ResultatsAthleteController extends ChangeNotifier {
  ResultatsAthleteController(this._lire);
  final Future<List<ResultatPublie>> Function() _lire;
  List<ResultatPublie> _resultats = const [];
  bool _chargement = false;
  String? _erreur;
  Future<void>? _requete;
  bool _detruit = false;

  List<ResultatPublie> get resultats => _resultats;
  bool get chargement => _chargement;
  String? get erreur => _erreur;

  Future<void> recharger() {
    final requete = _requete;
    if (requete != null) return requete;
    if (_detruit) return Future.value();
    final completion = Completer<void>();
    _requete = completion.future;
    unawaited(_charger(completion));
    return completion.future;
  }

  Future<void> _charger(Completer<void> completion) async {
    _chargement = true;
    _erreur = null;
    _notifier();
    try {
      final resultats = await _lire().timeout(const Duration(seconds: 20));
      if (!_detruit) _resultats = List.unmodifiable(resultats);
    } catch (e) {
      if (!_detruit) {
        _resultats = const [];
        _erreur = e is StateError ? e.message.toString() : 'Impossible d’actualiser les résultats. Vérifie ta connexion puis réessaie.';
      }
    } finally {
      _requete = null;
      _chargement = false;
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
