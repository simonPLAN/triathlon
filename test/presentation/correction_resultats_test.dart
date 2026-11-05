import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/resultat/corriger_resultat.dart';
import 'package:triathlon/application/use_cases/resultat/enregistrer_arrivee.dart';
import 'package:triathlon/application/use_cases/resultat/lister_resultats_manche.dart';
import 'package:triathlon/application/use_cases/resultat/marquer_athletes_hors_delai.dart';
import 'package:triathlon/domain/entities/athlete.dart';
import 'package:triathlon/domain/entities/edition_resultat.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/resultat.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/entities/statut_resultat.dart';
import 'package:triathlon/domain/ports/edition_resultats_repository.dart';
import 'package:triathlon/domain/ports/resultat_repository.dart';
import 'package:triathlon/domain/services/calcul_points.dart';
import 'package:triathlon/presentation/controllers/resultat_controller.dart';
import 'package:triathlon/presentation/formatters/temps_resultat.dart';
import 'package:triathlon/presentation/widgets/resultat/dialogue_correction_resultat.dart';

const athlete = Athlete(id: 'athlete', prenom: 'Alex', nom: 'Martin');
final depart = DateTime.utc(2026);
Manche manche({bool publiee = false}) => Manche(
  id: 'manche',
  epreuveId: 'epreuve',
  numero: 1,
  statut: StatutManche.terminee,
  resultatsPublies: publiee,
  dateCreation: depart,
  dateModification: depart,
  heureDepart: depart,
  heureFinDelai: depart.add(const Duration(hours: 1)),
  revisionResultats: 5,
);
Resultat resultat(String id, int position, int points) => Resultat(
  id: id,
  mancheId: 'manche',
  athlete: athlete,
  position: position,
  points: points,
  statut: StatutResultat.arrive,
  dateCreation: depart,
  dateModification: depart,
  tempsTotalMillisecondes: 60000,
  heureArrivee: depart.add(const Duration(minutes: 1)),
);

class EditionFake implements EditionResultatsRepository {
  ModificationResultat? derniere;
  Completer<EditionResultats>? attente;
  int appels = 0;
  @override
  Future<EditionResultats> editer(ModificationResultat modification) async {
    appels++;
    derniere = modification;
    return attente?.future ??
        EditionResultats(
          resultats: [resultat('autre', 1, 5), resultat('cible', 2, 4)],
          revision: 12,
          depublies: true,
        );
  }
}

class ResultatsFake extends Fake implements ResultatRepository {}

void main() {
  test('temps manuel : formats précis, virgule, durées longues et refus des formats invalides', () {
    expect(TempsResultat.lire('05:23.450'), 323450);
    expect(TempsResultat.lire('120:01,2'), 7201200);
    expect(TempsResultat.lire('00:00'), 0);
    expect(TempsResultat.formater(-1234), '-00:01.234');
    for (final texte in ['-1:00', '01:60', '1.5', '01:02.1234', '10081:00']) {
      expect(TempsResultat.lire(texte), isNull, reason: texte);
    }
  });
  test('le cas d’utilisation transmet la révision, le temps et le mode au port transactionnel', () async {
    final depot = EditionFake();
    await CorrigerResultat(depot).executer(
      manche: manche(publiee: true),
      athlete: athlete,
      resultat: resultat('cible', 1, 5),
      statut: StatutResultat.arrive,
      mode: ModeReclassement.decaler,
      position: 2,
      tempsMillisecondes: 61000,
      accepterDepublication: true,
      commentaire: ' Correction ',
    );
    expect(depot.derniere!.revision, 5);
    expect(depot.derniere!.tempsMillisecondes, 61000);
    expect(depot.derniere!.commentaire, 'Correction');
  });
  test('refuse les temps invalides, un échange sans place et une dépublication non confirmée', () {
    final depot = EditionFake();
    final corriger = CorrigerResultat(depot);
    expect(
      () => corriger.executer(
        manche: manche(),
        athlete: athlete,
        statut: StatutResultat.arrive,
        mode: ModeReclassement.temps,
        tempsMillisecondes: -1,
      ),
      throwsArgumentError,
    );
    expect(
      () => corriger.executer(
        manche: manche(),
        athlete: athlete,
        statut: StatutResultat.arrive,
        mode: ModeReclassement.echanger,
        position: 1,
        tempsMillisecondes: 1000,
      ),
      throwsArgumentError,
    );
    expect(
      () => corriger.executer(
        manche: manche(publiee: true),
        athlete: athlete,
        statut: StatutResultat.abandon,
        mode: ModeReclassement.decaler,
      ),
      throwsStateError,
    );
    expect(
      () => corriger.executer(
        manche: manche().copierAvec(statut: StatutManche.enCours),
        athlete: athlete,
        statut: StatutResultat.abandon,
        mode: ModeReclassement.decaler,
      ),
      throwsStateError,
    );
    expect(depot.appels, 0);
  });
  test(
    'le contrôleur remplace tout le classement et bloque une double soumission',
    () async {
      final depot = EditionFake()..attente = Completer<EditionResultats>();
      final resultats = ResultatsFake();
      final controller = ResultatController(
        ListerResultatsManche(resultats),
        EnregistrerArrivee(resultats, const CalculPoints()),
        CorrigerResultat(depot),
        MarquerAthletesHorsDelai(resultats),
      );
      final premier = controller.corrigerResultat(
        manche: manche(),
        athlete: athlete,
        resultat: resultat('cible', 1, 5),
        statut: StatutResultat.arrive,
        mode: ModeReclassement.decaler,
        position: 2,
        tempsMillisecondes: 60000,
      );
      final second = await controller.corrigerResultat(
        manche: manche(),
        athlete: athlete,
        resultat: resultat('cible', 1, 5),
        statut: StatutResultat.arrive,
        mode: ModeReclassement.decaler,
        position: 2,
        tempsMillisecondes: 60000,
      );
      expect(second, isNull);
      expect(depot.appels, 1);
      depot.attente!.complete(
        EditionResultats(
          resultats: [resultat('autre', 1, 5), resultat('cible', 2, 4)],
          revision: 9,
          depublies: false,
        ),
      );
      await premier;
      expect(controller.resultats.map((r) => r.id), ['autre', 'cible']);
      expect(controller.resultats.map((r) => r.points), [5, 4]);
      controller.dispose();
    },
  );
  testWidgets(
    'formulaire : temps invalide visible puis saisie manuelle valide',
    (tester) async {
      CorrectionResultat? reponse;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  reponse = await showDialog<CorrectionResultat>(
                    context: context,
                    builder: (_) => DialogueCorrectionResultat(
                      manche: manche(),
                      athlete: athlete,
                      nombreArrives: 2,
                    ),
                  );
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Utilise le format minutes:secondes.millisecondes.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('temps-manuel')),
        '01:02.003',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(reponse!.tempsMillisecondes, 62003);
      expect(reponse!.mode, ModeReclassement.temps);
    },
  );
  testWidgets('résultats publiés : confirmation de retrait obligatoire', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<CorrectionResultat>(
                context: context,
                builder: (_) => DialogueCorrectionResultat(
                  manche: manche(publiee: true),
                  athlete: athlete,
                  resultat: resultat('cible', 1, 5),
                  nombreArrives: 2,
                ),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Confirme le retrait de publication pour continuer.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.byType(DialogueCorrectionResultat), findsNothing);
  });
}
