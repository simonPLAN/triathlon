import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/epreuve/gerer_partage_epreuve.dart';
import 'package:triathlon/domain/entities/inscription.dart';
import 'package:triathlon/domain/entities/partage_epreuve.dart';
import 'package:triathlon/domain/ports/partage_epreuve_repository.dart';

class _DepotPartageMemoire implements PartageEpreuveRepository {
  String? epreuveAutorisee;
  String? pseudoAutorise;
  String? epreuveRetiree;
  String? coachRetire;

  @override
  Future<void> autoriser(String epreuveId, String pseudo) async {
    epreuveAutorisee = epreuveId;
    pseudoAutorise = pseudo;
  }

  @override
  Future<List<CoachAutoriseEpreuve>> listerCoachs(String epreuveId) async =>
      const [CoachAutoriseEpreuve(id: 'coach-2', pseudo: 'arbitre')];

  @override
  Future<List<EpreuvePartagee>> listerPartagees() async => const [];

  @override
  Future<List<Inscription>> listerParticipants(String mancheId) async =>
      const [];

  @override
  Future<void> retirer(String epreuveId, String coachId) async {
    epreuveRetiree = epreuveId;
    coachRetire = coachId;
  }
}

void main() {
  test('autorise un coach par son pseudo après normalisation', () async {
    final depot = _DepotPartageMemoire();
    final gerer = GererPartageEpreuve(depot);

    await gerer.autoriser(' epreuve-1 ', ' arbitre ');

    expect(depot.epreuveAutorisee, 'epreuve-1');
    expect(depot.pseudoAutorise, 'arbitre');
  });

  test('refuse une autorisation sans pseudo', () {
    final gerer = GererPartageEpreuve(_DepotPartageMemoire());

    expect(() => gerer.autoriser('epreuve-1', '   '), throwsArgumentError);
  });

  test('retire uniquement un coach identifié', () async {
    final depot = _DepotPartageMemoire();
    final gerer = GererPartageEpreuve(depot);

    await gerer.retirer('epreuve-1', 'coach-2');

    expect(depot.epreuveRetiree, 'epreuve-1');
    expect(depot.coachRetire, 'coach-2');
  });
}
