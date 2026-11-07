import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/manche/annuler_manche.dart';
import 'package:triathlon/application/use_cases/manche/demarrer_manche.dart';
import 'package:triathlon/application/use_cases/manche/enregistrer_premiere_arrivee.dart';
import 'package:triathlon/application/use_cases/manche/generer_manches_pour_epreuve.dart';
import 'package:triathlon/application/use_cases/manche/lister_manches.dart';
import 'package:triathlon/application/use_cases/manche/publier_resultats_manche.dart';
import 'package:triathlon/application/use_cases/manche/terminer_manche.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/ports/manche_repository.dart';
import 'package:triathlon/presentation/controllers/manche_controller.dart';

class DepotManches extends Fake implements MancheRepository {
  final List<String> publications = [];
  String? echecId;
  @override
  Future<Manche> modifier(Manche manche) async {
    if (manche.id == echecId) throw StateError('Connexion interrompue');
    publications.add(manche.id);
    return manche;
  }
}

Manche manche(String id, StatutManche statut, {bool publiee = false}) => Manche(
  id: id,
  epreuveId: 'e',
  numero: int.parse(id),
  statut: statut,
  resultatsPublies: publiee,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
);

MancheController creerController(DepotManches depot) => MancheController(
  GenererManchesPourEpreuve(depot),
  ListerManches(depot),
  DemarrerManche(depot),
  EnregistrerPremiereArrivee(depot),
  TerminerManche(depot),
  AnnulerManche(depot),
  PublierResultatsManche(depot),
);

void main() {
  test(
    'publie uniquement les manches terminées non publiées, sans doublon',
    () async {
      final depot = DepotManches();
      final controller = creerController(depot);
      addTearDown(controller.dispose);
      for (final m in [
        manche('1', StatutManche.terminee),
        manche('2', StatutManche.terminee, publiee: true),
        manche('3', StatutManche.enCours),
        manche('4', StatutManche.aVenir),
        manche('5', StatutManche.annulee),
        manche('6', StatutManche.terminee),
      ]) {
        controller.remplacerLocalement(m);
      }
      expect(await controller.publierTousLesResultats(), 2);
      expect(depot.publications, ['1', '6']);
      expect(await controller.publierTousLesResultats(), 0);
      expect(depot.publications, ['1', '6']);
      expect(controller.actionEnCours, isFalse);
    },
  );

  test(
    'une reprise après erreur ne republie pas les succès précédents',
    () async {
      final depot = DepotManches()..echecId = '2';
      final controller = creerController(depot);
      addTearDown(controller.dispose);
      controller.remplacerLocalement(manche('1', StatutManche.terminee));
      controller.remplacerLocalement(manche('2', StatutManche.terminee));
      expect(await controller.publierTousLesResultats(), isNull);
      expect(controller.erreur, contains('1 manche(s) publiée(s)'));
      expect(controller.actionEnCours, isFalse);
      depot.echecId = null;
      expect(await controller.publierTousLesResultats(), 1);
      expect(depot.publications, ['1', '2']);
    },
  );
}
