import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../application/use_cases/auth/confirmer_email.dart';

class ConfirmationEmailController extends ChangeNotifier {
  ConfirmationEmailController(this._confirmer);
  final ConfirmerEmail _confirmer;
  bool operationEnCours = false;
  bool lienActif = false;
  bool confirme = false;
  String? message;
  String? erreur;
  int secondesAvantRenvoi = 0;
  Timer? _compteARebours;
  bool _detruit = false;

  bool correspond(Uri lien) => _confirmer.correspond(lien);
  void _actualiser() {
    if (!_detruit) notifyListeners();
  }

  Future<void> renvoyer(String email) async {
    if (operationEnCours || secondesAvantRenvoi > 0) return;
    operationEnCours = true;
    erreur = null;
    message = null;
    _actualiser();
    try {
      await _confirmer.renvoyer(email);
      if (_detruit) return;
      message = 'Si cette adresse attend une confirmation, un e-mail a été envoyé. Vérifie aussi les courriers indésirables.';
      secondesAvantRenvoi = 60;
      _compteARebours?.cancel();
      _compteARebours = Timer.periodic(const Duration(seconds: 1), (timer) {
        secondesAvantRenvoi--;
        if (secondesAvantRenvoi <= 0) timer.cancel();
        _actualiser();
      });
    } catch (e) {
      erreur = _nettoyer(e);
    } finally {
      operationEnCours = false;
      _actualiser();
    }
  }

  Future<void> traiterLien(Uri lien) async {
    if (!correspond(lien) || operationEnCours) return;
    lienActif = true;
    confirme = false;
    erreur = null;
    message = null;
    operationEnCours = true;
    _actualiser();
    try {
      await _confirmer.confirmer(lien);
      confirme = true;
      message = 'Adresse e-mail confirmée. Tu peux maintenant te connecter.';
    } catch (e) {
      erreur = _nettoyer(e);
    } finally {
      operationEnCours = false;
      _actualiser();
    }
  }

  void fermerLien() {
    if (operationEnCours) return;
    lienActif = false;
    _actualiser();
  }

  String _nettoyer(Object e) => e.toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _detruit = true;
    _compteARebours?.cancel();
    super.dispose();
  }
}
