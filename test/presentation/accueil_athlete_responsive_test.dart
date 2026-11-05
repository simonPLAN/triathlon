import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/entities/profil_utilisateur.dart';
import 'package:triathlon/domain/entities/role_utilisateur.dart';
import 'package:triathlon/presentation/theme/theme_application.dart';
import 'package:triathlon/presentation/widgets/athlete/contenu_competitions_athlete.dart';
import 'package:triathlon/presentation/widgets/athlete/entete_athlete.dart';

void main() {
  testWidgets(
    'accueil vide à 320px, texte agrandi et actualisation disponible',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var actualisations = 0;
      var ouvertes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeApplication.clair,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ContenuCompetitionsAthlete(
              entete: const EnteteAthlete(
                profil: ProfilUtilisateur(
                  id: 'a',
                  prenom: 'Alexandrine',
                  nom: 'Martin',
                  role: RoleUtilisateur.athlete,
                ),
              ),
              competitions: const [],
              chargement: false,
              mesCompetitions: true,
              onRecharger: () async {
                actualisations++;
              },
              onVoirOuvertes: () {
                ouvertes++;
              },
              construireCarte: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final action = find.text('Voir les inscriptions ouvertes');
      await tester.scrollUntilVisible(
        action,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(ouvertes, 1);
      final scroll = find.byType(CustomScrollView);
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(scroll, const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(actualisations, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );
}
