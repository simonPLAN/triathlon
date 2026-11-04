import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/deconnecter_utilisateur.dart';
import 'package:triathlon/application/use_cases/inscrire_athlete.dart';
import 'package:triathlon/domain/entities/athlete.dart';
import 'package:triathlon/domain/ports/categorie_athlete_repository.dart';
import 'package:triathlon/presentation/controllers/athlete_controller.dart';
import 'package:triathlon/presentation/pages/athletes_page.dart';
import 'package:triathlon/presentation/theme/theme_application.dart';

class AthletesFake extends ChangeNotifier implements AthleteController {
  @override
  CategorieAthleteRepository? get categories => null;
  @override
  List<Athlete> athletes = [
    const Athlete(
      id: 'identifiant-technique-1',
      prenom: 'Élodie',
      nom: 'Martin',
    ),
    const Athlete(id: 'identifiant-technique-2', prenom: 'Alex', nom: 'Dupont'),
  ];
  @override
  bool chargement = false;
  @override
  String? erreur;
  @override
  Future<void> charger() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InscriptionFake extends Fake implements InscrireAthlete {}

class DeconnexionFake extends Fake implements DeconnecterUtilisateur {}

void main() {
  testWidgets('recherche sans accents, efface et masque les identifiants', (
    tester,
  ) async {
    final controller = AthletesFake();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeApplication.clair,
        home: AthletesPage(
          controller: controller,
          inscrireAthlete: InscriptionFake(),
          deconnecterUtilisateur: DeconnexionFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 athlète(s)'), findsOneWidget);
    expect(find.textContaining('identifiant-technique'), findsNothing);

    await tester.enterText(find.byType(TextField), 'MARTIN elodie');
    await tester.pumpAndSettle();
    expect(find.text('Élodie Martin'), findsOneWidget);
    expect(find.text('Alex Dupont'), findsNothing);

    await tester.enterText(find.byType(TextField), 'introuvable');
    await tester.pumpAndSettle();
    expect(find.text('Aucun athlète trouvé'), findsOneWidget);

    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Dupont'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la liste vide indique comment inscrire un invité', (
    tester,
  ) async {
    final controller = AthletesFake()..athletes = [];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeApplication.sombre,
        home: AthletesPage(
          controller: controller,
          inscrireAthlete: InscriptionFake(),
          deconnecterUtilisateur: DeconnexionFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucun athlète enregistré'), findsOneWidget);
    expect(find.textContaining('invité sans compte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
