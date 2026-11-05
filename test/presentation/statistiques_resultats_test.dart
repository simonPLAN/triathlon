import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/entities/donnee_statistique.dart';
import 'package:triathlon/presentation/theme/theme_application.dart';
import 'package:triathlon/presentation/widgets/resultat/statistiques_resultats.dart';

const donnees = [
  DonneeStatistique(
    athleteId: 'a',
    nomAthlete: 'Alice',
    epreuveId: 'natation',
    nomEpreuve: 'Natation',
    mancheId: 'm1',
    numeroManche: 1,
    points: 5,
    statut: 'arrive',
    tempsMillisecondes: 15000,
  ),
  DonneeStatistique(
    athleteId: 'b',
    nomAthlete: 'Benoît',
    epreuveId: 'course',
    nomEpreuve: 'Course à pied',
    mancheId: 'm2',
    numeroManche: 1,
    points: 4,
    statut: 'arrive',
    tempsMillisecondes: 65000,
  ),
  DonneeStatistique(
    athleteId: 'c',
    nomAthlete: 'Camille',
    epreuveId: 'course',
    nomEpreuve: 'Course à pied',
    mancheId: 'm2',
    numeroManche: 1,
    points: 0,
    statut: 'hors_delai',
  ),
];

Future<void> afficher(
  WidgetTester tester, {
  List<DonneeStatistique> lignes = donnees,
  double texte = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeApplication.clair,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(texte)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatistiquesResultats(
            donnees: lignes,
            provenance: 'Résultats publiés uniquement.',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sélectionne une épreuve et affiche ses vraies durées', (
    tester,
  ) async {
    await afficher(tester);
    await tester.tap(find.text('Temps par épreuve'));
    await tester.pumpAndSettle();
    final choix = find.text('E2 · Course à pied');
    await tester.ensureVisible(choix);
    await tester.tap(choix);
    await tester.pumpAndSettle();
    expect(find.text('1 temps mesurés'), findsOneWidget);
    expect(find.text('Moyenne : 1:05.000'), findsOneWidget);
    expect(find.text('Meilleur : 1:05.000'), findsOneWidget);
    expect(find.text('Médiane : 1:05.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statuts, barème et lecture à 320px avec texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await afficher(tester, texte: 2);
    final statuts = find.text('Statuts');
    await tester.ensureVisible(statuts);
    await tester.tap(statuts);
    await tester.pumpAndSettle();
    final horsDelai = find.text('Hors délai');
    await tester.ensureVisible(horsDelai);
    await tester.tap(horsDelai);
    await tester.pumpAndSettle();
    expect(find.text('1 sur 3 · 33.3 %'), findsOneWidget);
    final bareme = find.text('Comprendre les coefficients');
    await tester.ensureVisible(bareme);
    await tester.tap(bareme);
    await tester.pumpAndSettle();
    expect(find.text('Coefficients par catégorie'), findsOneWidget);
    expect(find.text('F 60-64 : 0,7210'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aucune donnée ne produit pas de statistiques fictives', (
    tester,
  ) async {
    await afficher(tester, lignes: []);
    expect(find.textContaining('apparaîtront après'), findsOneWidget);
    expect(find.text('0 points'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
