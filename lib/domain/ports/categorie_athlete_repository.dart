import '../entities/categorie_athlete.dart';

abstract interface class CategorieAthleteRepository {
  Future<CategorieAthlete> obtenir(String athleteId);
  Future<void> enregistrer(String athleteId, String? categorie);
}
