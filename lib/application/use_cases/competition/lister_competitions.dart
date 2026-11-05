import '../../../domain/entities/competition.dart';
import '../../../domain/ports/competition_repository.dart';

class ListerCompetitions {
  ListerCompetitions(this._competitionRepository);

  final CompetitionRepository _competitionRepository;

  Future<List<Competition>> executer() {
    return _competitionRepository.obtenirToutes();
  }
}
