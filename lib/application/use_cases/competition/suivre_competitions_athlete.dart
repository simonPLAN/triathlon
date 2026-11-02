import '../../../domain/entities/competition.dart';
import '../../../domain/entities/resultat_publie.dart';
import '../../../domain/ports/suivi_athlete_repository.dart';

class SuivreCompetitionsAthlete {
  SuivreCompetitionsAthlete(this._repository);
  final SuiviAthleteRepository _repository;

  Future<List<Competition>> listerInscriptions() =>
      _repository.obtenirCompetitionsInscrites();

  Future<List<ResultatPublie>> resultatsPublies(String competitionId) {
    if (competitionId.trim().isEmpty) {
      throw ArgumentError('La compétition est obligatoire.');
    }
    return _repository.obtenirResultatsPublies(competitionId.trim());
  }
}
