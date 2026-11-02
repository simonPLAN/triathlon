import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/competition/lister_competitions_ouvertes.dart';
import 'package:triathlon/application/use_cases/competition/suivre_competitions_athlete.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/resultat_publie.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';
import 'package:triathlon/domain/ports/competition_repository.dart';
import 'package:triathlon/domain/ports/suivi_athlete_repository.dart';
import 'package:triathlon/presentation/controllers/competitions_ouvertes_controller.dart';
import 'package:triathlon/presentation/pages/athlete/resultats_athlete_page.dart';

class CompetitionsFake extends Fake implements CompetitionRepository {}

class SuiviFake implements SuiviAthleteRepository {
  List<ResultatPublie> resultats = [];
  @override
  Future<List<Competition>> obtenirCompetitionsInscrites() async => [];
  @override
  Future<List<ResultatPublie>> obtenirResultatsPublies(String id) async =>
      resultats;
}

final competition = Competition(
  id: 'competition',
  nom: 'Triathlon',
  dateCompetition: DateTime(2026),
  coachId: 'coach',
  statut: StatutCompetition.terminee,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
  demarrageAutomatiqueMancheSuivante: false,
);

ResultatPublie resultat(String id, String nom, int points) => ResultatPublie(
  athleteId: id,
  nomAthlete: nom,
  epreuveId: 'epreuve',
  nomEpreuve: 'Natation',
  mancheId: 'manche',
  numeroManche: 1,
  position: points == 5 ? 1 : 2,
  points: points,
  statut: 'arrive',
  tempsMillisecondes: 61000,
);

void main() {
  testWidgets('affiche un état vide avant publication', (tester) async {
    final repo = SuiviFake();
    final controller = CompetitionsOuvertesController(
      ListerCompetitionsOuvertes(CompetitionsFake()),
      SuivreCompetitionsAthlete(repo),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultatsAthletePage(
          competition: competition,
          controller: controller,
          athleteId: 'moi',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Le coach n’a pas encore publié de résultats.'),
      findsOneWidget,
    );
    expect(
      find.text('Ton total : 0 point(s) sur les manches publiées'),
      findsOneWidget,
    );
  });

  testWidgets('montre le classement puis filtre les résultats personnels', (
    tester,
  ) async {
    final repo = SuiviFake()
      ..resultats = [
        resultat('autre', 'Julie Martin', 5),
        resultat('moi', 'Alex Dupont', 4),
      ];
    final controller = CompetitionsOuvertesController(
      ListerCompetitionsOuvertes(CompetitionsFake()),
      SuivreCompetitionsAthlete(repo),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultatsAthletePage(
          competition: competition,
          controller: controller,
          athleteId: 'moi',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Julie Martin'), findsOneWidget);
    expect(find.text('Alex Dupont'), findsOneWidget);
    expect(
      find.text('Ton total : 4 point(s) sur les manches publiées'),
      findsOneWidget,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Julie Martin'), findsNothing);
    expect(find.text('Alex Dupont'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  test('refuse un identifiant de compétition vide', () {
    expect(
      () => SuivreCompetitionsAthlete(SuiviFake()).resultatsPublies(' '),
      throwsArgumentError,
    );
  });
}
