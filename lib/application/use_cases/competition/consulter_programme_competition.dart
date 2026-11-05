import '../../../domain/entities/programme_competition.dart';
import '../../../domain/ports/programme_competition_repository.dart';

class ConsulterProgrammeCompetition {
  const ConsulterProgrammeCompetition(this._repository);
  final ProgrammeCompetitionRepository _repository;

  Future<ProgrammeCompetition> executer(String competitionId) async {
    if (competitionId.trim().isEmpty) {
      throw ArgumentError('La compétition est obligatoire.');
    }
    final programme = await _repository.obtenir(competitionId.trim());
    final epreuves =
        programme.epreuves.map((epreuve) {
          final manches = [...epreuve.manches]
            ..sort((a, b) {
              final numero = a.numero.compareTo(b.numero);
              return numero != 0 ? numero : a.id.compareTo(b.id);
            });
          return EpreuveProgramme(
            id: epreuve.id,
            nom: epreuve.nom,
            discipline: epreuve.discipline,
            distanceMetres: epreuve.distanceMetres,
            ordre: epreuve.ordre,
            manches: manches,
          );
        }).toList()..sort((a, b) {
          final ordre = a.ordre.compareTo(b.ordre);
          return ordre != 0 ? ordre : a.id.compareTo(b.id);
        });
    return ProgrammeCompetition(
      epreuves: epreuves,
      affectationsDisponibles: programme.affectationsDisponibles,
    );
  }
}
