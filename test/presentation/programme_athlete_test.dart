import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/competition/consulter_programme_competition.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/programme_competition.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/entities/type_discipline.dart';
import 'package:triathlon/domain/ports/programme_competition_repository.dart';
import 'package:triathlon/presentation/controllers/programme_athlete_controller.dart';
import 'package:triathlon/presentation/pages/athlete/programme_athlete_page.dart';

final competition = Competition(
  id: 'competition',
  nom: 'Triathlon',
  coachId: 'coach',
  dateCompetition: DateTime(2026),
  statut: StatutCompetition.ouverte,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
  demarrageAutomatiqueMancheSuivante: false,
);
EpreuveProgramme epreuve(
  String id,
  int ordre, {
  List<MancheProgramme> manches = const [],
}) => EpreuveProgramme(
  id: id,
  nom: id,
  discipline: TypeDiscipline.natation,
  distanceMetres: 750,
  ordre: ordre,
  manches: manches,
);

class DepotProgramme implements ProgrammeCompetitionRepository {
  String? dernierId;
  ProgrammeCompetition valeur = ProgrammeCompetition(epreuves: []);
  @override
  Future<ProgrammeCompetition> obtenir(String competitionId) async {
    dernierId = competitionId;
    return valeur;
  }
}

void main() {
  test(
    'trie les épreuves puis les manches et refuse une compétition vide',
    () async {
      final depot = DepotProgramme()
        ..valeur = ProgrammeCompetition(
          epreuves: [
            epreuve('Vélo', 2),
            epreuve(
              'Natation',
              1,
              manches: const [
                MancheProgramme(
                  id: 'm2',
                  numero: 2,
                  statut: StatutManche.enCours,
                ),
                MancheProgramme(
                  id: 'm1',
                  numero: 1,
                  statut: StatutManche.aVenir,
                ),
              ],
            ),
          ],
        );
      final consulter = ConsulterProgrammeCompetition(depot);
      final programme = await consulter.executer(' competition ');
      expect(depot.dernierId, 'competition');
      expect(programme.epreuves.map((e) => e.ordre), [1, 2]);
      expect(programme.epreuves.first.manches.map((m) => m.numero), [1, 2]);
      await expectLater(consulter.executer('  '), throwsArgumentError);
    },
  );

  test('la participation inconnue n’est pas assimilée à une affectation', () {
    const manche = MancheProgramme(
      id: 'm',
      numero: 1,
      statut: StatutManche.aVenir,
    );
    expect(manche.participe, isNull);
    expect(manche.ordreDepart, isNull);
  });

  testWidgets(
    'programme complet avant publication, statuts visibles et interface en lecture seule',
    (tester) async {
      final programme = ProgrammeCompetition(
        epreuves: [
          epreuve(
            'Natation',
            1,
            manches: [
              for (final (index, statut) in StatutManche.values.indexed)
                MancheProgramme(
                  id: 'm$index',
                  numero: index + 1,
                  statut: statut,
                ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProgrammeAthletePage(
            competition: competition,
            charger: () async => programme,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1. Natation'), findsOneWidget);
      expect(find.text('Natation • 750 m'), findsOneWidget);
      for (final libelle in ['À venir', 'En cours', 'Terminée', 'Annulée']) {
        expect(find.text(libelle), findsOneWidget);
      }
      expect(
        find.text('Participation à cette manche non définie.'),
        findsNWidgets(4),
      );
      expect(find.text('Ordre de départ non défini.'), findsNWidgets(4));
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.text('Démarrer'), findsNothing);
      expect(find.text('Publier'), findsNothing);
    },
  );

  testWidgets(
    'affiche les affectations et l’ordre seulement lorsque les données sont fournies',
    (tester) async {
      final programme = ProgrammeCompetition(
        affectationsDisponibles: true,
        epreuves: [
          epreuve(
            'Natation',
            1,
            manches: const [
              MancheProgramme(
                id: 'oui',
                numero: 1,
                statut: StatutManche.aVenir,
                participe: true,
                ordreDepart: 3,
              ),
              MancheProgramme(
                id: 'non',
                numero: 2,
                statut: StatutManche.aVenir,
                participe: false,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProgrammeAthletePage(
            competition: competition,
            charger: () async => programme,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tu participes à cette manche.'), findsOneWidget);
      expect(find.text('Tu n’es pas affecté à cette manche.'), findsOneWidget);
      expect(find.text('Ton ordre de départ : 3'), findsOneWidget);
      expect(
        find.text(
          'Les affectations individuelles et les ordres de départ ne sont pas encore définis.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'erreur de lecture avec reprise puis programme vide et actualisation',
    (tester) async {
      bool erreur = true;
      int appels = 0;
      ProgrammeCompetition valeur = ProgrammeCompetition(epreuves: []);
      await tester.pumpWidget(
        MaterialApp(
          home: ProgrammeAthletePage(
            competition: competition,
            charger: () async {
              appels++;
              if (erreur) throw StateError('Programme inaccessible.');
              return valeur;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Programme inaccessible.'), findsOneWidget);
      erreur = false;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Le coach n’a pas encore défini les épreuves.'),
        findsOneWidget,
      );
      valeur = ProgrammeCompetition(epreuves: [epreuve('Natation', 1)]);
      await tester.tap(find.byTooltip('Actualiser le programme'));
      await tester.pumpAndSettle();
      expect(find.text('1. Natation'), findsOneWidget);
      expect(appels, 3);
    },
  );

  test('les actualisations simultanées partagent une lecture et la fin après fermeture est ignorée', () async {
    final attente = Completer<ProgrammeCompetition>();
    int appels = 0;
    final controller = ProgrammeAthleteController(() {
      appels++;
      return attente.future;
    });
    final premiere = controller.recharger();
    final seconde = controller.recharger();
    expect(appels, 1);
    controller.dispose();
    attente.complete(ProgrammeCompetition(epreuves: []));
    await Future.wait([premiere, seconde]);
    expect(controller.programme, isNull);
  });
}
