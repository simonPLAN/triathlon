import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/entities/athlete.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/epreuve.dart';
import 'package:triathlon/domain/entities/inscription.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/resultat.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/entities/type_discipline.dart';
import 'package:triathlon/presentation/controllers/inscription_controller.dart';
import 'package:triathlon/presentation/controllers/manche_controller.dart';
import 'package:triathlon/presentation/controllers/resultat_controller.dart';
import 'package:triathlon/presentation/pages/resultat/resultats_manche_page.dart';

class ManchesFake extends ChangeNotifier implements MancheController {
  ManchesFake(this.manches);
  @override
  List<Manche> manches;
  int clotures = 0;
  int departs = 0;
  @override
  bool get actionEnCours => false;
  @override
  String? get erreur => null;
  @override
  Future<void> charger(String id) async {}
  @override
  Future<Manche?> terminer(Manche m) async {
    clotures++;
    final terminee = m.copierAvec(statut: StatutManche.terminee);
    manches = manches.map((x) => x.id == m.id ? terminee : x).toList();
    return terminee;
  }

  @override
  Future<Manche?> demarrer(Manche m) async {
    departs++;
    final demarree = m.demarrer(heure: DateTime.now());
    manches = manches.map((x) => x.id == m.id ? demarree : x).toList();
    return demarree;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InscriptionsFake extends ChangeNotifier implements InscriptionController {
  @override
  bool get operationEnCours => false;
  @override
  bool get chargement => false;
  @override
  String? get erreur => null;
  @override
  List<Inscription> get inscriptions => [
    Inscription(
      id: 'i',
      competitionId: 'c',
      athlete: const Athlete(id: 'a', prenom: 'Julie', nom: 'Martin'),
      dateInscription: DateTime(2026),
    ),
  ];
  @override
  Future<void> charger({required String competitionId}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ResultatsFake extends ChangeNotifier implements ResultatController {
  int marquages = 0;
  int athletesTraites = 0;
  String? mancheChargee;
  @override
  bool get operationEnCours => false;
  @override
  bool get chargement => false;
  @override
  String? get erreur => null;
  @override
  List<Resultat> get resultats => [];
  @override
  bool possedeResultatPour(String id) => false;
  @override
  Future<void> charger(String id) async {
    mancheChargee = id;
  }

  @override
  void reinitialiser() {
    mancheChargee = null;
  }

  @override
  Future<List<Resultat>?> marquerHorsDelai({
    required Manche manche,
    required List<Athlete> athletes,
  }) async {
    marquages++;
    athletesTraites = athletes.length;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scenario in [
    (auto: true, suivante: true),
    (auto: false, suivante: true),
    (auto: true, suivante: false),
  ]) {
    testWidgets('clôture à zéro et enchaînement $scenario', (tester) async {
      final maintenant = DateTime.now();
      final manche = Manche(
        id: 'm1',
        epreuveId: 'e',
        numero: 1,
        statut: StatutManche.enCours,
        resultatsPublies: false,
        dateCreation: maintenant,
        dateModification: maintenant,
        heureDepart: maintenant.subtract(const Duration(minutes: 2)),
        heurePremiereArrivee: maintenant.subtract(const Duration(seconds: 61)),
        heureFinDelai: maintenant.subtract(const Duration(seconds: 1)),
      );
      final suivante = Manche(
        id: 'm2',
        epreuveId: 'e',
        numero: 2,
        statut: StatutManche.aVenir,
        resultatsPublies: false,
        dateCreation: maintenant,
        dateModification: maintenant,
      );
      final manches = ManchesFake([manche, if (scenario.suivante) suivante]);
      final resultats = ResultatsFake();
      final inscriptions = InscriptionsFake();
      addTearDown(manches.dispose);
      addTearDown(resultats.dispose);
      addTearDown(inscriptions.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ResultatsManchePage(
            competition: Competition(
              id: 'c',
              nom: 'Triathlon',
              coachId: 'coach',
              statut: StatutCompetition.enCours,
              dateCompetition: maintenant,
              dateCreation: maintenant,
              dateModification: maintenant,
              demarrageAutomatiqueMancheSuivante: scenario.auto,
            ),
            epreuve: Epreuve(
              id: 'e',
              competitionId: 'c',
              nom: 'Natation',
              discipline: TypeDiscipline.natation,
              distanceMetres: 100,
              nombreManches: 2,
              ordre: 1,
              dureeLimiteSecondes: 60,
              dateCreation: maintenant,
              dateModification: maintenant,
            ),
            manche: manche,
            mancheController: manches,
            resultatController: resultats,
            inscriptionController: inscriptions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(manches.clotures, 1);
      expect(resultats.marquages, 1);
      expect(resultats.athletesTraites, 1);
      expect(manches.manches.first.estTerminee, isTrue);
      final enchaine = scenario.auto && scenario.suivante;
      expect(manches.departs, enchaine ? 1 : 0);
      expect(
        find.text('Résultats - Manche ${enchaine ? 2 : 1}'),
        findsOneWidget,
      );
      if (enchaine) {
        expect(resultats.mancheChargee, 'm2');
        expect(find.text('Julie Martin'), findsOneWidget);
      }
      expect(find.text('Clôturer le délai ?'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(manches.clotures, 1);
      expect(resultats.marquages, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
