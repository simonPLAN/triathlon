import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/resultat/consulter_resultats_competition.dart';
import 'package:triathlon/domain/entities/epreuve.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/resultat.dart';
import 'package:triathlon/domain/entities/athlete.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/entities/statut_resultat.dart';
import 'package:triathlon/domain/entities/type_discipline.dart';
import 'package:triathlon/domain/ports/epreuve_repository.dart';
import 'package:triathlon/domain/ports/manche_repository.dart';
import 'package:triathlon/domain/ports/resultat_repository.dart';

final date = DateTime.utc(2026, 11, 4);
final epreuve = Epreuve(
  id: 'e',
  competitionId: 'c',
  discipline: TypeDiscipline.natation,
  nom: 'Natation',
  distanceMetres: 100,
  nombreManches: 2,
  ordre: 1,
  dureeLimiteSecondes: 60,
  dateCreation: date,
  dateModification: date,
);

class EpreuvesFake implements EpreuveRepository {
  @override
  Future<List<Epreuve>> obtenirParCompetition(String id) async => [epreuve];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class ManchesFake implements MancheRepository {
  @override
  Future<List<Manche>> obtenirParEpreuve(String id) async => [
    for (var n = 1; n <= 2; n++)
      Manche(
        id: 'm$n',
        epreuveId: id,
        numero: n,
        statut: StatutManche.terminee,
        resultatsPublies: false,
        dateCreation: date,
        dateModification: date,
      ),
  ];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class ResultatsFake implements ResultatRepository {
  bool echouer = false;
  @override
  Future<List<Resultat>> obtenirParManche(String id) async {
    if (echouer && id == 'm2') throw StateError('Réseau indisponible');
    return [
      Resultat(
        id: id,
        mancheId: id,
        athlete: const Athlete(id: 'a', prenom: 'A', nom: 'B'),
        points: 5,
        statut: StatutResultat.arrive,
        dateCreation: date,
        dateModification: date,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('lecture indépendante et complète par les ports', () async {
    final service = ConsulterResultatsCompetition(
      EpreuvesFake(),
      ManchesFake(),
      ResultatsFake(),
    );
    final donnees = await service.executer('c');
    expect(donnees.lignes.map((l) => l.manche.id), ['m1', 'm2']);
    expect(donnees.epreuves.single.nom, 'Natation');
    expect(() => donnees.lignes.clear(), throwsUnsupportedError);
  });
  test('une erreur ne produit jamais un classement partiel', () async {
    final resultats = ResultatsFake()..echouer = true;
    final service = ConsulterResultatsCompetition(
      EpreuvesFake(),
      ManchesFake(),
      resultats,
    );
    await expectLater(service.executer('c'), throwsStateError);
  });
}
