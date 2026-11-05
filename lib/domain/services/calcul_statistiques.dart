import '../entities/donnee_statistique.dart';

class StatistiquesEpreuve {
  const StatistiquesEpreuve({
    required this.epreuveId,
    required this.nomEpreuve,
    required this.resultats,
    required this.arrivees,
    required this.points,
    this.meilleurTempsMillisecondes,
    this.moyenneTempsMillisecondes,
    this.medianeTempsMillisecondes,
  });
  final String epreuveId, nomEpreuve;
  final int resultats, arrivees, points;
  final int? meilleurTempsMillisecondes;
  final double? moyenneTempsMillisecondes, medianeTempsMillisecondes;
}

/// Les temps absents ou invalides et les non-arrivants sont exclus des
/// statistiques de durée, jamais remplacés par zéro.
class CalculStatistiques {
  const CalculStatistiques();

  List<DonneeStatistique> uniques(Iterable<DonneeStatistique> donnees) {
    final uniques = <(String, String), DonneeStatistique>{};
    for (final ligne in donnees) {
      uniques[(ligne.mancheId, ligne.athleteId)] = ligne;
    }
    return List.unmodifiable(uniques.values);
  }

  List<StatistiquesEpreuve> parEpreuve(Iterable<DonneeStatistique> donnees) {
    final groupes = <String, List<DonneeStatistique>>{};
    for (final ligne in uniques(donnees)) {
      groupes.putIfAbsent(ligne.epreuveId, () => []).add(ligne);
    }
    return List.unmodifiable(
      groupes.entries.map((groupe) {
        final lignes = groupe.value;
        final temps =
            lignes
                .where((r) => r.statut == 'arrive')
                .map((r) => r.tempsMillisecondes)
                .whereType<int>()
                .where((ms) => ms >= 0)
                .toList()
              ..sort();
        final milieu = temps.length ~/ 2;
        return StatistiquesEpreuve(
          epreuveId: groupe.key,
          nomEpreuve: lignes.first.nomEpreuve,
          resultats: lignes.length,
          arrivees: lignes.where((r) => r.statut == 'arrive').length,
          points: lignes.fold(0, (somme, r) => somme + r.points),
          meilleurTempsMillisecondes: temps.isEmpty ? null : temps.first,
          moyenneTempsMillisecondes: temps.isEmpty
              ? null
              : temps.fold<int>(0, (somme, ms) => somme + ms) / temps.length,
          medianeTempsMillisecondes: temps.isEmpty
              ? null
              : temps.length.isOdd
              ? temps[milieu].toDouble()
              : (temps[milieu - 1] + temps[milieu]) / 2,
        );
      }),
    );
  }

  Map<String, int> repartitionStatuts(Iterable<DonneeStatistique> donnees) {
    final compte = <String, int>{};
    for (final ligne in uniques(donnees)) {
      compte.update(ligne.statut, (n) => n + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(compte);
  }
}
