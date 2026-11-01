import '../../domain/entities/athlete.dart';
import '../../domain/ports/athlete_repository.dart';

class AjouterAthlete {
  AjouterAthlete(this._repository);

  final AthleteRepository _repository;

  Future<void> executer({
    required String prenom,
    required String nom,
  }) async {
    final prenomNettoye = prenom.trim();
    final nomNettoye = nom.trim();

    if (prenomNettoye.isEmpty || nomNettoye.isEmpty) {
      throw ArgumentError('Le prenom et le nom sont obligatoires.');
    }

    final athlete = Athlete(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      prenom: prenomNettoye,
      nom: nomNettoye,
    );

    await _repository.ajouter(athlete);
  }
}
