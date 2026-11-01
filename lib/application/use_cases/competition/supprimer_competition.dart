import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/ports/competition_repository.dart';

class SupprimerCompetition {
  SupprimerCompetition(this._competitionRepository);

  final CompetitionRepository _competitionRepository;

  Future<void> executer(Competition competition) async {
    if (competition.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (competition.statut != StatutCompetition.brouillon) {
      throw StateError(
        'Seule une compétition en brouillon peut être supprimée.',
      );
    }

    await _competitionRepository.supprimer(competition.id);
  }
}
