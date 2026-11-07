import '../../domain/entities/athlete.dart';
import '../../domain/ports/athlete_repository.dart';

class ListerAthletes {
  ListerAthletes(this._repository);

  final AthleteRepository _repository;

  Future<List<Athlete>> executer() => _repository.obtenirTous();
}
