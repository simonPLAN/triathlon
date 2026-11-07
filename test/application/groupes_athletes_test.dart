import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/athlete/gerer_groupes_athletes.dart';
import 'package:triathlon/domain/entities/groupe_athletes.dart';
import 'package:triathlon/domain/ports/groupe_athletes_repository.dart';

class _DepotGroupes implements GroupeAthletesRepository {
  GroupeAthletes? dernier;

  @override
  Future<List<GroupeAthletes>> lister() async =>
      dernier == null ? const [] : [dernier!];

  @override
  Future<GroupeAthletes> enregistrer({
    String? id,
    required String nom,
    required List<String> athleteIds,
  }) async {
    dernier = GroupeAthletes(
      id: id ?? 'groupe-1',
      nom: nom,
      athleteIds: athleteIds,
    );
    return dernier!;
  }

  @override
  Future<void> supprimer(String id) async {
    if (dernier?.id == id) dernier = null;
  }
}

void main() {
  test('crée un groupe normalisé sans membres en double', () async {
    final depot = _DepotGroupes();
    final service = GererGroupesAthletes(depot);

    final groupe = await service.enregistrer(
      nom: '  Juniors  ',
      athleteIds: const ['a1', 'a2', 'a1'],
    );

    expect(groupe.nom, 'Juniors');
    expect(groupe.athleteIds, {'a1', 'a2'});
  });

  test('refuse un nom invalide et un groupe vide', () {
    final service = GererGroupesAthletes(_DepotGroupes());

    expect(
      () => service.enregistrer(nom: 'A', athleteIds: const ['a1']),
      throwsArgumentError,
    );
    expect(
      () => service.enregistrer(nom: 'Juniors', athleteIds: const []),
      throwsArgumentError,
    );
  });
}
