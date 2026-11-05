import 'package:flutter/foundation.dart';

import '../../application/use_cases/auth/supprimer_mon_compte.dart';

class SuppressionCompteController extends ChangeNotifier {
  SuppressionCompteController(this._supprimer);
  final SupprimerMonCompte _supprimer;
  bool enCours = false;
  bool supprime = false;
  bool termine = false;
  String? erreur;
  bool _detruit = false;

  Future<void> confirmer(String motDePasse, bool confirmation) async {
    if (enCours || termine) return;
    enCours = true;
    erreur = null;
    _notifier();
    try {
      if (!supprime) {
        await _supprimer.executer(
          motDePasse: motDePasse,
          confirmation: confirmation,
        );
        supprime = true;
      }
      await _supprimer.effacerSessionLocale();
      termine = true;
    } catch (e) {
      erreur = supprime
          ? 'Ton compte est supprimé. Réessaie de terminer le nettoyage sur cet appareil.'
          : e
                .toString()
                .replaceFirst('Bad state: ', '')
                .replaceFirst('Invalid argument(s): ', '');
    } finally {
      enCours = false;
      _notifier();
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
