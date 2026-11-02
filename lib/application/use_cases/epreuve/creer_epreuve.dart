import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/type_discipline.dart';
import '../../../domain/ports/epreuve_repository.dart';

class CreerEpreuve {
  CreerEpreuve(this._epreuveRepository);

  final EpreuveRepository _epreuveRepository;

  Future<Epreuve> executer({
    required String competitionId,
    required TypeDiscipline discipline,
    required String nom,
    required int distanceMetres,
    required int nombreManches,
    required int ordre,
    required int dureeLimiteSecondes,
  }) async {
    final competitionIdNettoye = competitionId.trim();
    final nomNettoye = nom.trim();

    _valider(
      competitionId: competitionIdNettoye,
      nom: nomNettoye,
      distanceMetres: distanceMetres,
      nombreManches: nombreManches,
      ordre: ordre,
      dureeLimiteSecondes: dureeLimiteSecondes,
    );

    final maintenant = DateTime.now();

    final epreuve = Epreuve(
      id: '',
      competitionId: competitionIdNettoye,
      discipline: discipline,
      nom: nomNettoye,
      distanceMetres: distanceMetres,
      nombreManches: nombreManches,
      ordre: ordre,
      dureeLimiteSecondes: dureeLimiteSecondes,
      dateCreation: maintenant,
      dateModification: maintenant,
    );

    return _epreuveRepository.creer(epreuve);
  }

  void _valider({
    required String competitionId,
    required String nom,
    required int distanceMetres,
    required int nombreManches,
    required int ordre,
    required int dureeLimiteSecondes,
  }) {
    if (competitionId.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (nom.isEmpty) {
      throw ArgumentError('Le nom de l’épreuve est obligatoire.');
    }

    if (nom.length < 3) {
      throw ArgumentError(
        'Le nom de l’épreuve doit contenir '
        'au moins 3 caractères.',
      );
    }

    if (distanceMetres <= 0) {
      throw ArgumentError('La distance doit être supérieure à zéro.');
    }

    if (nombreManches <= 0) {
      throw ArgumentError(
        'Le nombre de manches doit être '
        'supérieur à zéro.',
      );
    }

    if (ordre <= 0) {
      throw ArgumentError(
        'L’ordre de l’épreuve doit être '
        'supérieur à zéro.',
      );
    }

    if (dureeLimiteSecondes <= 0) {
      throw ArgumentError(
        'La durée limite doit être '
        'supérieure à zéro.',
      );
    }
  }
}
