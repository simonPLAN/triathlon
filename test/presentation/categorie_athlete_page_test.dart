import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/entities/categorie_athlete.dart';
import 'package:triathlon/domain/ports/categorie_athlete_repository.dart';
import 'package:triathlon/presentation/pages/compte/categorie_athlete_page.dart';
import 'package:triathlon/presentation/theme/theme_application.dart';

class DepotCategorie implements CategorieAthleteRepository {
  DepotCategorie(this.categorie, {this.modifiable = true});
  final String? categorie;
  final bool modifiable;
  @override
  Future<CategorieAthlete> obtenir(String athleteId) async =>
      CategorieAthlete(categorie: categorie, modifiable: modifiable);
  @override
  Future<void> enregistrer(String athleteId, String? categorie) async {}
}

void main() {
  testWidgets('coefficient déclaré lisible à 320px et texte 2x', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeApplication.clair,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CategorieAthletePage(
          repository: DepotCategorie('F 60-64'),
          athleteId: 'a',
          nomAthlete: 'Alexandrine Martin',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final valeur = find.text('Coefficient : 0,7210');
    await tester.ensureVisible(valeur);
    expect(valeur, findsOneWidget);
    final action = find.text('Enregistrer');
    await tester.ensureVisible(action);
    expect(action, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catégorie inconnue et lecture seule ne plantent pas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategorieAthletePage(
          repository: DepotCategorie('F 35-39', modifiable: false),
          athleteId: 'a',
          nomAthlete: 'Alice',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coefficient non défini'), findsOneWidget);
    expect(find.text('Enregistrer'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
