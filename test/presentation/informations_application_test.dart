import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/presentation/pages/compte/informations_application_page.dart';

void main() {
  testWidgets('lien public invalide non ouvert, absence expliquée', (
    tester,
  ) async {
    var appels = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: InformationsApplicationPage(
          politiqueUrl: 'http://site.test/confidentialite',
          suppressionUrl: '',
          emailSupport: '',
          ouvrirLien: (_) async {
            appels++;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lire la politique de confidentialité'), findsNothing);
    expect(appels, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ouverture HTTPS explicite et erreur compréhensible', (
    tester,
  ) async {
    Uri? recue;
    await tester.pumpWidget(
      MaterialApp(
        home: InformationsApplicationPage(
          politiqueUrl: 'https://club.test/confidentialite',
          suppressionUrl: '',
          emailSupport: '',
          ouvrirLien: (uri) async {
            recue = uri;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.text('Lire la politique de confidentialité'),
    );
    await tester.tap(find.text('Lire la politique de confidentialité'));
    await tester.pumpAndSettle();
    expect(recue?.scheme, 'https');
    expect(find.textContaining('Impossible d’ouvrir le lien'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
