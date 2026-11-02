import '../../../domain/ports/competition_repository.dart';

class VerifierCompetitionBrouillon {
  VerifierCompetitionBrouillon(this._repository);
  final CompetitionRepository _repository;

  Future<void> executer(String competitionId) async {
    final competition = await _repository.obtenirParId(competitionId);
    if (competition == null || !competition.estBrouillon) {
      throw StateError(
        'Seule une compétition en brouillon peut être configurée.',
      );
    }
  }
}
