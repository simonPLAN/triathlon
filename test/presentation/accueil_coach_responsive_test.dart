import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/deconnecter_utilisateur.dart';
import 'package:triathlon/domain/entities/profil_utilisateur.dart';
import 'package:triathlon/domain/entities/role_utilisateur.dart';
import 'package:triathlon/presentation/pages/coach/coach_dashboard_page.dart';
import 'package:triathlon/presentation/theme/theme_application.dart';

class DeconnexionAttente extends Fake implements DeconnecterUtilisateur {
  int appels = 0;
  final attente = Completer<void>();
  @override
  Future<void> executer() {
    appels++;
    return attente.future;
  }
}

void main() {
  testWidgets('accueil coach à 320px texte 2x et double déconnexion protégée', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deconnexion = DeconnexionAttente();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeApplication.clair,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CoachDashboardPage(
          profil: const ProfilUtilisateur(
            id: 'coach',
            prenom: 'Alexandrine',
            nom: 'Martin',
            role: RoleUtilisateur.coach,
          ),
          deconnecterUtilisateur: deconnexion,
          onVoirCompetitions: () {},
          onVoirAthletes: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('LE MANS TRIATHLON'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Mon compte'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(deconnexion.appels, 1);
    deconnexion.attente.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
