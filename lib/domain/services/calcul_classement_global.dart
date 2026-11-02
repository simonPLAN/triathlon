import '../entities/classement_global_athlete.dart';
import '../entities/resultat_publie.dart';

class CalculClassementGlobal {
  const CalculClassementGlobal();

  List<ClassementGlobalAthlete> calculer(Iterable<ResultatPublie> resultats) {
    final groupes = <String, List<ResultatPublie>>{};
    for (final resultat in resultats) {
      groupes.putIfAbsent(resultat.athleteId, () => []).add(resultat);
    }
    final totaux =
        groupes.entries.map((groupe) {
          return (
            id: groupe.key,
            nom: groupe.value.first.nomAthlete,
            points: groupe.value.fold<int>(0, (total, r) => total + r.points),
            manches: groupe.value.map((r) => r.mancheId).toSet().length,
          );
        }).toList()..sort((a, b) {
          final points = b.points.compareTo(a.points);
          if (points != 0) return points;
          final nom = a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
          return nom != 0 ? nom : a.id.compareTo(b.id);
        });

    var rang = 0;
    int? pointsPrecedents;
    final classement = <ClassementGlobalAthlete>[];
    for (var i = 0; i < totaux.length; i++) {
      final total = totaux[i];
      if (pointsPrecedents != total.points) rang = i + 1;
      pointsPrecedents = total.points;
      classement.add(
        ClassementGlobalAthlete(
          athleteId: total.id,
          nom: total.nom,
          points: total.points,
          nombreManches: total.manches,
          rang: rang,
        ),
      );
    }
    return List.unmodifiable(classement);
  }
}
