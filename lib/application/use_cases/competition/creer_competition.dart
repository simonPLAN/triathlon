import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/ports/competition_repository.dart';

class CreerCompetition {
  CreerCompetition(this._competitionRepository);

  final CompetitionRepository _competitionRepository;

  Future<Competition> executer({
    required String nom,
    required DateTime dateCompetition,
    required String coachId,
    required bool demarrageAutomatiqueMancheSuivante,
    String? description,
    String? lieu,
  }) async {
    final nomNettoye = nom.trim();
    final descriptionNettoyee = _nettoyerTexteFacultatif(description);
    final lieuNettoye = _nettoyerTexteFacultatif(lieu);

    if (nomNettoye.isEmpty) {
      throw ArgumentError('Le nom de la compétition est obligatoire.');
    }

    if (coachId.trim().isEmpty) {
      throw ArgumentError('Le coach de la compétition est obligatoire.');
    }

    final maintenant = DateTime.now();

    final competition = Competition(
      id: '',
      nom: nomNettoye,
      description: descriptionNettoyee,
      lieu: lieuNettoye,
      dateCompetition: dateCompetition,
      statut: StatutCompetition.brouillon,
      coachId: coachId,
      demarrageAutomatiqueMancheSuivante: demarrageAutomatiqueMancheSuivante,
      dateCreation: maintenant,
      dateModification: maintenant,
    );

    return _competitionRepository.creer(competition);
  }

  String? _nettoyerTexteFacultatif(String? valeur) {
    final valeurNettoyee = valeur?.trim();

    if (valeurNettoyee == null || valeurNettoyee.isEmpty) {
      return null;
    }

    return valeurNettoyee;
  }
}
