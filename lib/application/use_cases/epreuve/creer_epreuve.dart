import '../../../domain/entities/epreuve.dart';
import '../../../domain/services/validation_epreuve.dart';
import 'verifier_competition_brouillon.dart';
import '../../../domain/entities/type_discipline.dart';
import '../../../domain/ports/epreuve_repository.dart';

class CreerEpreuve {
  CreerEpreuve(this._epreuveRepository, this._verifierCompetition);

  final VerifierCompetitionBrouillon _verifierCompetition;

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

    ValidationEpreuve.verifier(epreuve);
    await _verifierCompetition.executer(competitionIdNettoye);
    return _epreuveRepository.creer(epreuve);
  }
}
