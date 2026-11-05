import '../entities/athlete.dart';

abstract interface class AthleteRepository {
  Future<List<Athlete>> obtenirTous();
  Future<void> ajouter(Athlete athlete);
}
