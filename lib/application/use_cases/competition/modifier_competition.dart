import '../../../domain/entities/competition.dart';
import '../../../domain/ports/competition_repository.dart';

class ModifierCompetition {
  ModifierCompetition(this._competitionRepository);

  final CompetitionRepository _competitionRepository;

  Future<Competition> executer({
    required Competition competition,
    required String nom,
    required DateTime dateCompetition,
    String? description,
    String? lieu,
  }) async {
    final nomNettoye = nom.trim();
    final descriptionNettoyee = _nettoyerTexteFacultatif(description);
    final lieuNettoye = _nettoyerTexteFacultatif(lieu);

    if (competition.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (nomNettoye.isEmpty) {
      throw ArgumentError('Le nom de la compétition est obligatoire.');
    }

    final competitionModifiee = competition.copierAvec(
      nom: nomNettoye,
      description: descriptionNettoyee,
      lieu: lieuNettoye,
      dateCompetition: dateCompetition,
      dateModification: DateTime.now(),
    );

    return _competitionRepository.modifier(competitionModifiee);
  }

  String? _nettoyerTexteFacultatif(String? valeur) {
    final valeurNettoyee = valeur?.trim();

    if (valeurNettoyee == null || valeurNettoyee.isEmpty) {
      return null;
    }

    return valeurNettoyee;
  }
}
