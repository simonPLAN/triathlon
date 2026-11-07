import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/entities/resultat_publie.dart';
import 'package:triathlon/domain/services/calcul_classement_global.dart';

ResultatPublie resultat(String athlete, String manche, int points) =>
    ResultatPublie(
      athleteId: athlete,
      nomAthlete: athlete,
      epreuveId: manche,
      nomEpreuve: manche,
      mancheId: manche,
      numeroManche: 1,
      position: null,
      points: points,
      statut: points == 0 ? 'hors_delai' : 'arrive',
      tempsMillisecondes: null,
    );

void main() {
  test('cumule les points de toutes les manches et épreuves', () {
    final classement = const CalculClassementGlobal().calculer([
      resultat('Julie', 'natation', 5),
      resultat('Alex', 'natation', 4),
      resultat('Julie', 'velo', 0),
      resultat('Alex', 'velo', 5),
    ]);
    expect(classement.map((r) => r.nom), ['Alex', 'Julie']);
    expect(classement.map((r) => r.points), [9, 5]);
    expect(classement.map((r) => r.nombreManches), [2, 2]);
    expect(classement.map((r) => r.rang), [1, 2]);
  });

  test('conserve les ex aequo et les athlètes à zéro point', () {
    final classement = const CalculClassementGlobal().calculer([
      resultat('Julie', 'm1', 5),
      resultat('Alex', 'm1', 5),
      resultat('Chris', 'm1', 0),
    ]);
    expect(classement.map((r) => r.rang), [1, 1, 3]);
    expect(classement.last.points, 0);
  });

  test('aucun résultat donne un classement vide', () {
    expect(const CalculClassementGlobal().calculer([]), isEmpty);
  });
}
