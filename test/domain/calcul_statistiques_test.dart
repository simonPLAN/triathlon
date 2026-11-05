import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/entities/donnee_statistique.dart';
import 'package:triathlon/domain/services/calcul_statistiques.dart';
import 'package:triathlon/domain/services/coefficients_athletes.dart';

DonneeStatistique ligne(
  String id,
  int? ms, {
  String statut = 'arrive',
  String epreuve = 'e',
}) => DonneeStatistique(
  athleteId: id,
  nomAthlete: id,
  epreuveId: epreuve,
  nomEpreuve: epreuve,
  mancheId: 'm',
  numeroManche: 1,
  points: statut == 'arrive' ? 10 : 0,
  statut: statut,
  tempsMillisecondes: ms,
);

void main() {
  const calcul = CalculStatistiques();
  test('moyenne et médiane excluent temps inconnus et non arrivants', () {
    final stats = calcul.parEpreuve([
      ligne('a', 1000),
      ligne('b', 3000),
      ligne('c', 8000),
      ligne('d', null),
      ligne('e', 500000, statut: 'abandon'),
      ligne('f', -10),
    ]).single;
    expect(stats.resultats, 6);
    expect(stats.arrivees, 5);
    expect(stats.meilleurTempsMillisecondes, 1000);
    expect(stats.moyenneTempsMillisecondes, 4000);
    expect(stats.medianeTempsMillisecondes, 3000);
  });
  test('paire athlete/manche unique et épreuves distinctes', () {
    final stats = calcul.parEpreuve([
      ligne('a', 1000),
      ligne('a', 2000),
      ligne('b', 4000),
      ligne('c', 6000, epreuve: 'autre'),
    ]);
    expect(stats.length, 2);
    expect(stats.first.resultats, 2);
    expect(stats.first.medianeTempsMillisecondes, 3000);
    expect(
      calcul.repartitionStatuts([
        ligne('a', 1),
        ligne('b', null, statut: 'hors_delai'),
      ]),
      {'arrive': 1, 'hors_delai': 1},
    );
  });
  test('absence de temps ne devient pas une durée zéro', () {
    expect(
      calcul.parEpreuve([ligne('a', null)]).single.moyenneTempsMillisecondes,
      isNull,
    );
    expect(calcul.parEpreuve([]), isEmpty);
  });
  test('barème exact fourni et limites sans interpolation', () {
    expect(CoefficientsAthletes.bareme.length, 12);
    expect(CoefficientsAthletes.pourCategorie('M 18-24'), .9698);
    expect(CoefficientsAthletes.pourCategorie('F 60-64'), .721);
    expect(CoefficientsAthletes.categorie(sexe: 'F', age: 64), 'F 60-64');
    for (final age in [17, 35, 39, 45, 49, 55, 59, 65]) {
      expect(CoefficientsAthletes.categorie(sexe: 'M', age: age), isNull);
    }
    expect(CoefficientsAthletes.categorie(sexe: '', age: 30), isNull);
    expect(CoefficientsAthletes.pourCategorie(null), isNull);
  });
}
