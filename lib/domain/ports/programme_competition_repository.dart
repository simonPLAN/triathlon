import '../entities/programme_competition.dart';

abstract interface class ProgrammeCompetitionRepository {
  Future<ProgrammeCompetition> obtenir(String competitionId);
}
