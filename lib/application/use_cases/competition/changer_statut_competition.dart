import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/ports/competition_repository.dart';

class ChangerStatutCompetition {
  ChangerStatutCompetition(this._competitionRepository);

  final CompetitionRepository _competitionRepository;

  Future<Competition> executer({
    required Competition competition,
    required StatutCompetition nouveauStatut,
  }) async {
    if (competition.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (competition.statut == nouveauStatut) {
      throw StateError('La compétition possède déjà ce statut.');
    }

    final competitionActualisee = switch (nouveauStatut) {
      StatutCompetition.ouverte => competition.ouvrir(),
      StatutCompetition.enCours => competition.demarrer(),
      StatutCompetition.terminee => competition.terminer(),
      StatutCompetition.annulee => competition.annuler(),

      // On n’autorise pas encore le retour vers brouillon.
      StatutCompetition.brouillon => throw StateError(
        'Une compétition ne peut pas revenir au statut brouillon.',
      ),
    };

    return _competitionRepository.modifier(competitionActualisee);
  }
}
