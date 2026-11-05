import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/ports/inscription_repository.dart';

class InscrireUtilisateurConnecte {
  InscrireUtilisateurConnecte(this._inscriptionRepository);

  final InscriptionRepository _inscriptionRepository;

  Future<Inscription> executer({required Competition competition}) {
    if (competition.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (competition.statut != StatutCompetition.ouverte) {
      throw StateError(
        'Les inscriptions ne sont pas ouvertes '
        'pour cette compétition.',
      );
    }

    return _inscriptionRepository.inscrireUtilisateurConnecte(
      competitionId: competition.id,
    );
  }
}
