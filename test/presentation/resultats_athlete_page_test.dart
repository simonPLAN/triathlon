import 'dart:async';

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
  int lectures = 0;
  bool erreur = false;
  Completer<List<ResultatPublie>>? attente;
  @override
  Future<List<Competition>> obtenirCompetitionsInscrites() async => [];
  @override
  Future<List<ResultatPublie>> obtenirResultatsPublies(String id) async {
    lectures++;
    if (erreur) throw StateError('Connexion indisponible. Réessaie.');
    if (attente != null) return attente!.future;
    return List.of(resultats);
  }
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

  testWidgets(
    'le bouton actualise le classement immédiatement sans changer de vue',
    (tester) async {
      final repo = SuiviFake()..resultats = [resultat('moi', 'Alex Dupont', 4)];
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
      expect(repo.lectures, 1);
      repo.attente = Completer<List<ResultatPublie>>();
      await tester.tap(find.byTooltip('Actualiser'));
      await tester.pump();
      expect(repo.lectures, 2);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Actualiser',
              ),
            )
            .onPressed,
        isNull,
      );
      repo.attente!.complete([resultat('moi', 'Alex Actualisé', 5)]);
      await tester.pumpAndSettle();
      expect(find.text('Alex Actualisé'), findsOneWidget);
      expect(find.text('Alex Dupont'), findsNothing);
      expect(
        find.text('Ton total : 5 point(s) sur les manches publiées'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Général'))
            .selected,
        isTrue,
      );
    },
  );

  testWidgets(
    'actualisation conserve la vue par manche et le filtre personnel',
    (tester) async {
      final repo = SuiviFake()..resultats = [resultat('moi', 'Alex Dupont', 4)];
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
      await tester.tap(find.text('Par manche'));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      repo.resultats = [
        resultat('moi', 'Alex Actualisé', 5),
        resultat('autre', 'Julie Martin', 4),
      ];
      await tester.tap(find.byTooltip('Actualiser'));
      await tester.pumpAndSettle();
      expect(find.text('Alex Actualisé'), findsOneWidget);
      expect(find.text('Julie Martin'), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Par manche'))
            .selected,
        isTrue,
      );
    },
  );

  testWidgets(
    'un retrait de publication efface les anciens résultats au rafraîchissement',
    (tester) async {
      final repo = SuiviFake()..resultats = [resultat('moi', 'Alex Dupont', 5)];
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
      repo.resultats = [];
      await tester.tap(find.byTooltip('Actualiser'));
      await tester.pumpAndSettle();
      expect(find.text('Alex Dupont'), findsNothing);
      expect(
        find.text('Le coach n’a pas encore publié de résultats.'),
        findsOneWidget,
      );
      expect(
        find.text('Ton total : 0 point(s) sur les manches publiées'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'erreur réseau puis nouvelle tentative recharge les résultats sans changer de vue',
    (tester) async {
      final repo = SuiviFake()..resultats = [resultat('moi', 'Alex Dupont', 4)];
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
      repo.erreur = true;
      await tester.tap(find.byTooltip('Actualiser'));
      await tester.pumpAndSettle();
      expect(find.text('Connexion indisponible. Réessaie.'), findsOneWidget);
      repo.erreur = false;
      repo.resultats = [resultat('moi', 'Alex Actualisé', 5)];
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Alex Actualisé'), findsOneWidget);
      expect(repo.lectures, 3);
    },
  );

  testWidgets('le glissement actualise aussi une liste initialement vide', (
    tester,
  ) async {
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
    repo.resultats = [resultat('moi', 'Alex Actualisé', 5)];
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(repo.lectures, 2);
    expect(find.text('Alex Actualisé'), findsOneWidget);
  });

  testWidgets('le retour dans l’application actualise les résultats affichés', (
    tester,
  ) async {
    final repo = SuiviFake()..resultats = [resultat('moi', 'Alex Dupont', 4)];
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
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    repo.resultats = [resultat('moi', 'Alex Actualisé', 5)];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.lectures, 2);
    expect(find.text('Alex Actualisé'), findsOneWidget);
  });

  test('refuse un identifiant de compétition vide', () {
    expect(
      () => SuivreCompetitionsAthlete(SuiviFake()).resultatsPublies(' '),
      throwsArgumentError,
    );
  });
}
