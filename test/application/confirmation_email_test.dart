import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/auth/confirmer_email.dart';
import 'package:triathlon/domain/ports/confirmation_email_repository.dart';
import 'package:triathlon/presentation/controllers/confirmation_email_controller.dart';

class FauxConfirmation implements ConfirmationEmailRepository {
  int envois = 0;
  int echanges = 0;
  String? adresse;
  bool session = false;
  Completer<void>? attente;
  @override
  bool get possedeSession => session;
  @override
  Future<void> renvoyer(String email) async {
    envois++;
    adresse = email;
    await attente?.future;
  }
  @override
  Future<void> confirmer(String code) async { echanges++; }
}

void main() {
  final retour = Uri.parse('triathlon://auth/confirm-email');

  test('valide et normalise l’adresse avant l’envoi', () async {
    final depot = FauxConfirmation();
    final confirmer = ConfirmerEmail(depot, retour);
    await expectLater(confirmer.renvoyer('pas-un-email'), throwsArgumentError);
    expect(depot.envois, 0);
    await confirmer.renvoyer('  Athlete@Example.org ');
    expect(depot.adresse, 'athlete@example.org');
  });

  test('refuse liens étrangers, erreurs, absence de code sans échange', () async {
    final depot = FauxConfirmation();
    final confirmer = ConfirmerEmail(depot, retour);
    await expectLater(confirmer.confirmer(Uri.parse('autre://auth/confirm-email?code=abc')), throwsArgumentError);
    await expectLater(confirmer.confirmer(Uri.parse('triathlon://auth/confirm-email?error_code=otp_expired')), throwsStateError);
    await expectLater(confirmer.confirmer(retour), throwsStateError);
    expect(depot.echanges, 0);
    await confirmer.confirmer(retour.replace(queryParameters: {'code':'abc'}));
    expect(depot.echanges, 1);
  });

  test('une session existante reste intacte et empêche l’échange', () async {
    final depot = FauxConfirmation()..session = true;
    final confirmer = ConfirmerEmail(depot, retour);
    await expectLater(confirmer.confirmer(retour.replace(queryParameters: {'code':'abc'})), throwsStateError);
    expect(depot.echanges, 0);
    expect(depot.session, isTrue);
  });

  testWidgets('envoi protégé pendant requête et délai de renvoi', (tester) async {
    final depot = FauxConfirmation()..attente = Completer<void>();
    final controleur = ConfirmationEmailController(ConfirmerEmail(depot, retour));
    final premier = controleur.renvoyer('a@example.org');
    await controleur.renvoyer('a@example.org');
    expect(depot.envois, 1);
    depot.attente!.complete();
    await premier;
    expect(controleur.secondesAvantRenvoi, 60);
    await controleur.renvoyer('a@example.org');
    expect(depot.envois, 1);
    await tester.pump(const Duration(seconds: 60));
    expect(controleur.secondesAvantRenvoi, 0);
    await controleur.renvoyer('a@example.org');
    expect(depot.envois, 2);
    controleur.dispose();
  });

  test('erreur du lien visible, reprise sans déconnexion', () async {
    final depot = FauxConfirmation();
    final controleur = ConfirmationEmailController(ConfirmerEmail(depot, retour));
    await controleur.traiterLien(retour);
    expect(controleur.lienActif, isTrue);
    expect(controleur.erreur, isNotNull);
    expect(controleur.confirme, isFalse);
    await controleur.traiterLien(retour.replace(queryParameters: {'code':'abc'}));
    expect(controleur.confirme, isTrue);
    expect(controleur.erreur, isNull);
    controleur.fermerLien();
    expect(controleur.lienActif, isFalse);
    controleur.dispose();
  });
}
