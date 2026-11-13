import '../../../domain/entities/competition.dart';
import '../../../domain/entities/fichier_affiche_epreuve.dart';
import '../../../domain/services/validation_affiche_epreuve.dart';
import '../../../domain/ports/competition_repository.dart';

class ModifierCompetition {
  ModifierCompetition(this._competitionRepository);

  final CompetitionRepository _competitionRepository;

  Future<Competition> executer({
    required Competition competition,
    required String nom,
    required DateTime dateCompetition,
    required bool demarrageAutomatiqueMancheSuivante,
    String? description,
    String? lieu,
    FichierAfficheEpreuve? image,
    bool supprimerImage = false,
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
      demarrageAutomatiqueMancheSuivante: demarrageAutomatiqueMancheSuivante,
      dateModification: DateTime.now(),
    );

    var enregistree = await _competitionRepository.modifier(
      competitionModifiee,
    );
    if (image != null) {
      ValidationAfficheEpreuve.verifierFichier(image);
      enregistree = await _competitionRepository.enregistrerImage(
        enregistree,
        image,
      );
    } else if (supprimerImage && enregistree.imageUrl != null) {
      enregistree = await _competitionRepository.supprimerImage(enregistree);
    }
    return enregistree;
  }

  String? _nettoyerTexteFacultatif(String? valeur) {
    final valeurNettoyee = valeur?.trim();

    if (valeurNettoyee == null || valeurNettoyee.isEmpty) {
      return null;
    }

    return valeurNettoyee;
  }
}
