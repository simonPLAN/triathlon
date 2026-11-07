import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/ports/suppression_compte_repository.dart';
import 'package:triathlon/application/use_cases/auth/supprimer_mon_compte.dart';
import 'package:triathlon/presentation/controllers/suppression_compte_controller.dart';
import 'package:triathlon/presentation/pages/compte/supprimer_compte_page.dart';

class DepotSuppression implements SuppressionCompteRepository {
  int suppressions = 0;
  int nettoyages = 0;
  String? motDePasse;
  bool erreurSuppression = false;
  bool erreurNettoyage = false;
  Completer<void>? attente;

  @override
  Future<void> supprimer(String motDePasse) async {
    suppressions++;
    this.motDePasse = motDePasse;
    if (erreurSuppression) throw StateError('Mot de passe incorrect.');
    await attente?.future;
  }

  @override
  Future<void> effacerSessionLocale() async {
    nettoyages++;
    if (erreurNettoyage) throw StateError('Stockage indisponible.');
  }
}

void main() {
  test('confirmation explicite et mot de passe requis avant appel serveur', () {
    final depot = DepotSuppression();
    final useCase = SupprimerMonCompte(depot);
    expect(
      () => useCase.executer(motDePasse: 'secret', confirmation: false),
      throwsArgumentError,
    );
    expect(
      () => useCase.executer(motDePasse: '', confirmation: true),
      throwsArgumentError,
    );
    expect(depot.suppressions, 0);
  });

  test('un seul appel lors de doubles soumissions', () async {
    final depot = DepotSuppression()..attente = Completer<void>();
    final controller = SuppressionCompteController(SupprimerMonCompte(depot));
    final enCours = controller.confirmer(' secret avec espaces ', true);
    await controller.confirmer(' secret avec espaces ', true);
    expect(depot.suppressions, 1);
    expect(depot.nettoyages, 0);
    depot.attente!.complete();
    await enCours;
    expect(depot.motDePasse, ' secret avec espaces ');
    expect(controller.termine, isTrue);
    expect(depot.nettoyages, 1);
    controller.dispose();
  });

  test('échec serveur conserve la session et permet de réessayer', () async {
    final depot = DepotSuppression()..erreurSuppression = true;
    final controller = SuppressionCompteController(SupprimerMonCompte(depot));
    await controller.confirmer('incorrect', true);
    expect(controller.supprime, isFalse);
    expect(controller.erreur, 'Mot de passe incorrect.');
    expect(depot.nettoyages, 0);
    depot.erreurSuppression = false;
    await controller.confirmer('correct', true);
    expect(controller.termine, isTrue);
    controller.dispose();
  });

  test('nettoyage réessayé sans demander une seconde suppression', () async {
    final depot = DepotSuppression()..erreurNettoyage = true;
    final controller = SuppressionCompteController(SupprimerMonCompte(depot));
    await controller.confirmer('secret', true);
    expect(controller.supprime, isTrue);
    expect(controller.termine, isFalse);
    depot.erreurNettoyage = false;
    await controller.confirmer('', false);
    expect(depot.suppressions, 1);
    expect(depot.nettoyages, 2);
    expect(controller.termine, isTrue);
    controller.dispose();
  });

  testWidgets(
    'confirmation obligatoire, erreur visible et retour à la connexion',
    (tester) async {
      final depot = DepotSuppression()..erreurSuppression = true;
      final useCase = SupprimerMonCompte(depot);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        SupprimerComptePage(supprimerMonCompte: useCase),
                  ),
                ),
                child: const Text('Connexion'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Connexion'));
      await tester.pumpAndSettle();
      final bouton = find.text('Supprimer définitivement mon compte');
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      expect(depot.suppressions, 0);
      await tester.ensureVisible(
        find.byKey(const ValueKey('mot-de-passe-suppression')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('mot-de-passe-suppression')),
        'secret',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(find.text('Mot de passe incorrect.'), findsOneWidget);
      expect(depot.nettoyages, 0);
      depot.erreurSuppression = false;
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(find.text('Connexion'), findsOneWidget);
      expect(
        find.text('Ton compte et tes données personnelles ont été supprimés.'),
        findsOneWidget,
      );
      expect(depot.nettoyages, 1);
    },
  );
}
