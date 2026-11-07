import '../entities/groupe_athletes.dart';

abstract interface class GroupeAthletesRepository {
  Future<List<GroupeAthletes>> lister();

  Future<GroupeAthletes> enregistrer({
    String? id,
    required String nom,
    required List<String> athleteIds,
  });

  Future<void> supprimer(String id);
}
