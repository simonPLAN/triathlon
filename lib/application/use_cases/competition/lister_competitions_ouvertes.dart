import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/ports/competition_repository.dart';

class ListerCompetitionsOuvertes {
  ListerCompetitionsOuvertes(this._competitionRepository);

  final CompetitionRepository _competitionRepository;

  Future<List<Competition>> executer() async {
    final competitions = await _competitionRepository.obtenirOuvertes();

    // Protection supplémentaire côté application.
    return competitions
        .where((competition) => competition.statut == StatutCompetition.ouverte)
        .toList(growable: false);
  }
}
