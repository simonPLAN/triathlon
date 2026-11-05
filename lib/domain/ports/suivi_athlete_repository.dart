import '../entities/competition.dart';
import '../entities/resultat_publie.dart';

abstract interface class SuiviAthleteRepository {
  Future<List<Competition>> obtenirCompetitionsInscrites();
  Future<List<ResultatPublie>> obtenirResultatsPublies(String competitionId);
}
