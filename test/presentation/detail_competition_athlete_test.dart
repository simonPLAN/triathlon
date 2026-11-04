import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/competition/lister_competitions_ouvertes.dart';
import 'package:triathlon/application/use_cases/competition/suivre_competitions_athlete.dart';
import 'package:triathlon/presentation/controllers/competitions_ouvertes_controller.dart';
import 'package:triathlon/presentation/pages/athlete/detail_competition_athlete_page.dart';
import 'etat_inscription_athlete_test.dart' as fixtures;

void main() {
  testWidgets('détail en lecture seule avec inscription, programme et résultats distincts', (tester) async {
    final depot = fixtures.DepotInscriptions()..actuelle = fixtures.inscription(42);
    final inscriptions = fixtures.controller(depot);
    final competitions = CompetitionsOuvertesController(
      ListerCompetitionsOuvertes(fixtures.DepotCompetitions()),
      SuivreCompetitionsAthlete(fixtures.DepotSuivi(depot)),
    );
    var programmes = 0;
    var resultats = 0;
    await tester.pumpWidget(MaterialApp(
      home: DetailCompetitionAthletePage(
        competition: fixtures.competition(),
        competitions: competitions,
        inscriptions: inscriptions,
        onInscrire: (_) async {},
        onDesinscrire: (_) async {},
        onProgramme: (_) => programmes++,
        onResultats: (_) => resultats++,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Détail de la compétition'), findsOneWidget);
    expect(find.text('Inscrit'), findsOneWidget);
    expect(find.text('Dossard n°42'), findsOneWidget);
    expect(find.text('Modifier la compétition'), findsNothing);
    await tester.ensureVisible(find.text('Voir le programme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir le programme'));
    await tester.ensureVisible(find.text('Résultats publiés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Résultats publiés'));
    expect(programmes, 1);
    expect(resultats, 1);
    await tester.pumpWidget(const SizedBox());
    inscriptions.dispose();
    competitions.dispose();
  });
}
