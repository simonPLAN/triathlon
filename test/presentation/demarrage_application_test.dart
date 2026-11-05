import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/presentation/pages/demarrage_application.dart';

void main() {
  testWidgets('erreur de démarrage avec reprise sans détail technique', (
    tester,
  ) async {
    var tentatives = 0;
    await tester.pumpWidget(
      DemarrageApplication(
        charger: () async {
          if (tentatives++ == 0) throw StateError('secret=NE_PAS_AFFICHER');
          return const MaterialApp(home: Scaffold(body: Text('Espace prêt')));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Impossible de démarrer'), findsOneWidget);
    expect(find.textContaining('NE_PAS_AFFICHER'), findsNothing);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Espace prêt'), findsOneWidget);
    expect(tentatives, 2);
  });
}
