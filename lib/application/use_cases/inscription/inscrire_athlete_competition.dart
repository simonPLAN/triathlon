import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/inscription_repository.dart';

class InscrireAthleteCompetition {
  InscrireAthleteCompetition(this._inscriptionRepository);

  final InscriptionRepository _inscriptionRepository;

  Future<Inscription> executer({
    required String competitionId,
    required String athleteId,
    int? numeroDossard,
  }) {
    final competitionIdNettoye = competitionId.trim();

    final athleteIdNettoye = athleteId.trim();

    if (competitionIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (athleteIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’athlète est obligatoire.');
    }

    if (numeroDossard != null && numeroDossard <= 0) {
      throw ArgumentError('Le numéro de dossard doit être supérieur à zéro.');
    }

    return _inscriptionRepository.inscrire(
      competitionId: competitionIdNettoye,
      athleteId: athleteIdNettoye,
      numeroDossard: numeroDossard,
    );
  }
}
