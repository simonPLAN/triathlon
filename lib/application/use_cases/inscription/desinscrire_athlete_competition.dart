import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/inscription_repository.dart';

class DesinscrireAthleteCompetition {
  DesinscrireAthleteCompetition(this._inscriptionRepository);

  final InscriptionRepository _inscriptionRepository;

  Future<void> executer(Inscription inscription) async {
    final inscriptionId = inscription.id.trim();

    if (inscriptionId.isEmpty) {
      throw ArgumentError('L’identifiant de l’inscription est obligatoire.');
    }

    await _inscriptionRepository.desinscrire(inscriptionId);
  }
}
