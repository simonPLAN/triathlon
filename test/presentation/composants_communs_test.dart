import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/presentation/theme/theme_application.dart';
import 'package:triathlon/presentation/widgets/commun/badge_statut.dart';
import 'package:triathlon/presentation/widgets/commun/bouton_action_principale.dart';
import 'package:triathlon/presentation/widgets/commun/carte_section.dart';
import 'package:triathlon/presentation/widgets/commun/etat_vide.dart';
import 'package:triathlon/presentation/widgets/commun/message_erreur.dart';

void main() {
  for (final luminosite in Brightness.values) {
    testWidgets('composants lisibles en $luminosite avec texte agrandi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeApplication.creer(luminosite),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: [
                CarteSection(
                  titre: 'Résultats de la compétition',
                  sousTitre: 'Les classements de toutes les manches',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final ton in TonBadgeStatut.values)
                        BadgeStatut(
                          libelle: 'En cours',
                          icone: Icons.timer_outlined,
                          ton: ton,
                        ),
                    ],
                  ),
                ),
                EtatVide(
                  titre: 'Aucune compétition',
                  description: 'Crée une compétition pour commencer.',
                  libelleAction: 'Créer une compétition',
                  onAction: () {},
                ),
                MessageErreur(
                  message: 'Connexion indisponible.',
                  onReessayer: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Résultats de la compétition'), findsOneWidget);
    });
  }

  testWidgets(
    'le bouton principal bloque les doubles appuis pendant le chargement',
    (tester) async {
      var appels = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeApplication.clair,
          home: Scaffold(
            body: BoutonActionPrincipale(
              libelle: 'Publier tous les résultats',
              enCours: true,
              onPressed: () => appels++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      expect(appels, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
