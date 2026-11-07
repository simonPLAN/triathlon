import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/epreuve/configurer_epreuves.dart';
import 'package:triathlon/application/use_cases/epreuve/creer_epreuve.dart';
import 'package:triathlon/application/use_cases/epreuve/verifier_competition_brouillon.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/epreuve.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/entities/type_discipline.dart';
import 'package:triathlon/domain/ports/competition_repository.dart';
import 'package:triathlon/domain/ports/epreuve_repository.dart';
import 'package:triathlon/domain/ports/manche_repository.dart';

final epreuve = Epreuve(
  id: 'e1',
  competitionId: 'c',
  nom: 'Natation',
  discipline: TypeDiscipline.natation,
  distanceMetres: 100,
  nombreManches: 2,
  ordre: 1,
  dureeLimiteSecondes: 60,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
);

class CompetitionsFake extends Fake implements CompetitionRepository {
  StatutCompetition statut = StatutCompetition.brouillon;
  @override
  Future<Competition?> obtenirParId(String id) async => Competition(
    id: id,
    nom: 'Triathlon',
    statut: statut,
    coachId: 'coach',
    dateCompetition: DateTime(2026),
    dateCreation: DateTime(2026),
    dateModification: DateTime(2026),
    demarrageAutomatiqueMancheSuivante: false,
  );
}

class EpreuvesFake extends Fake implements EpreuveRepository {
  List<Epreuve> liste = [epreuve, epreuve.copierAvec(id: 'e2', ordre: 2)];
  int mutations = 0;
  List<String>? ordre;
  @override
  Future<List<Epreuve>> obtenirParCompetition(String id) async => liste;
  @override
  Future<Epreuve?> obtenirParId(String id) async =>
      liste.where((e) => e.id == id).firstOrNull;
  @override
  Future<Epreuve> creer(Epreuve e) async {
    mutations++;
    return e;
  }

  @override
  Future<Epreuve> modifier(Epreuve e) async {
    mutations++;
    return e;
  }

  @override
  Future<void> supprimer(String id) async {
    mutations++;
  }

  @override
  Future<void> reordonner(String id, List<String> ids) async {
    mutations++;
    ordre = ids;
  }
}

class ManchesFake extends Fake implements MancheRepository {
  List<Manche> liste = [];
  @override
  Future<List<Manche>> obtenirParEpreuve(String id) async => liste;
}

void main() {
  late CompetitionsFake competitions;
  late EpreuvesFake epreuves;
  late ManchesFake manches;
  late ConfigurerEpreuves configurer;
  late CreerEpreuve creer;
  setUp(() {
    competitions = CompetitionsFake();
    epreuves = EpreuvesFake();
    manches = ManchesFake();
    final verifier = VerifierCompetitionBrouillon(competitions);
    configurer = ConfigurerEpreuves(epreuves, manches, verifier);
    creer = CreerEpreuve(epreuves, verifier);
  });

  test('modifie tous les champs et normalise le nom', () async {
    final resultat = await configurer.modifier(
      epreuve.copierAvec(
        nom: ' Natation 200 m ',
        distanceMetres: 200,
        nombreManches: 3,
        dureeLimiteSecondes: 90,
      ),
    );
    expect(resultat.nom, 'Natation 200 m');
    expect(resultat.nombreManches, 3);
    expect(resultat.dureeLimiteSecondes, 90);
    expect(epreuves.mutations, 1);
  });

  for (final statut in [
    StatutCompetition.ouverte,
    StatutCompetition.enCours,
    StatutCompetition.terminee,
    StatutCompetition.annulee,
  ]) {
    test(
      'refuse création, modification, suppression et ordre en $statut',
      () async {
        competitions.statut = statut;
        await expectLater(configurer.modifier(epreuve), throwsStateError);
        await expectLater(configurer.supprimer(epreuve), throwsStateError);
        await expectLater(
          configurer.reordonner('c', ['e2', 'e1']),
          throwsStateError,
        );
        await expectLater(
          creer.executer(
            competitionId: 'c',
            discipline: TypeDiscipline.natation,
            nom: 'Natation',
            distanceMetres: 100,
            nombreManches: 1,
            ordre: 1,
            dureeLimiteSecondes: 60,
          ),
          throwsStateError,
        );
        expect(epreuves.mutations, 0);
      },
    );
  }

  test(
    'protège une manche déjà démarrée même si la compétition est en brouillon',
    () async {
      manches.liste = [
        Manche(
          id: 'm',
          epreuveId: 'e1',
          numero: 1,
          statut: StatutManche.enCours,
          heureDepart: DateTime(2026),
          resultatsPublies: false,
          dateCreation: DateTime(2026),
          dateModification: DateTime(2026),
        ),
      ];
      await expectLater(configurer.modifier(epreuve), throwsStateError);
      await expectLater(configurer.supprimer(epreuve), throwsStateError);
      await expectLater(
        configurer.reordonner('c', ['e2', 'e1']),
        throwsStateError,
      );
      expect(epreuves.mutations, 0);
    },
  );

  test('refuse un ordre incomplet, dupliqué ou étranger', () async {
    for (final ids in [
      ['e1'],
      ['e1', 'e1'],
      ['e1', 'autre'],
    ]) {
      await expectLater(configurer.reordonner('c', ids), throwsArgumentError);
    }
    expect(epreuves.mutations, 0);
    await configurer.reordonner('c', ['e2', 'e1']);
    expect(epreuves.ordre, ['e2', 'e1']);
  });

  test('refuse les valeurs invalides avant tout enregistrement', () async {
    for (final invalide in [
      epreuve.copierAvec(distanceMetres: 0),
      epreuve.copierAvec(nombreManches: 1001),
      epreuve.copierAvec(dureeLimiteSecondes: -1),
      epreuve.copierAvec(ordre: 0),
      epreuve.copierAvec(nom: 'a'),
    ]) {
      await expectLater(configurer.modifier(invalide), throwsArgumentError);
    }
    expect(epreuves.mutations, 0);
  });

  test('supprime une épreuve dont toutes les manches sont à venir', () async {
    await configurer.supprimer(epreuve);
    expect(epreuves.mutations, 1);
  });
}
