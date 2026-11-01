import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/services/calcul_points.dart';
void main() {
  const calculPoints = CalculPoints();

  test('le premier recoit 5 points', () {
    expect(calculPoints.pourPosition(1), 5);
  });

  test('au-dela de la cinquieme place, aucun point', () {
    expect(calculPoints.pourPosition(6), 0);
  });

  test('une position invalide declenche une erreur', () {
    expect(() => calculPoints.pourPosition(0), throwsArgumentError);
  });
}
