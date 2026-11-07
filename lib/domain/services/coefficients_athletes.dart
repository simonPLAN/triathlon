/// Barème fourni par l'organisateur. Une catégorie absente reste inconnue.
/// Ces coefficients ne modifient pas automatiquement un classement officiel.
abstract final class CoefficientsAthletes {
  static const bareme = <String, double>{
    'M 18-24': 0.9698,
    'F 18-24': 0.9543,
    'M 25-29': 0.9921,
    'F 25-29': 0.9982,
    'M 30-34': 1.0,
    'F 30-34': 1.0,
    'M 40-44': 0.9630,
    'F 40-44': 0.8671,
    'M 50-54': 0.8728,
    'F 50-54': 0.7839,
    'M 60-64': 0.8262,
    'F 60-64': 0.721,
  };

  static double? pourCategorie(String? categorie) => bareme[categorie];

  static String? categorie({required String sexe, required int age}) {
    if (sexe != 'M' && sexe != 'F') return null;
    for (final tranche in [
      (18, 24),
      (25, 29),
      (30, 34),
      (40, 44),
      (50, 54),
      (60, 64),
    ]) {
      if (age >= tranche.$1 && age <= tranche.$2) {
        return '$sexe ${tranche.$1}-${tranche.$2}';
      }
    }
    return null;
  }
}
