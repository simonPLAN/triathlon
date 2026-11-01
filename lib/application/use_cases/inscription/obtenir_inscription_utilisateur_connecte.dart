import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/inscription_repository.dart';

class ObtenirInscriptionUtilisateurConnecte {
  ObtenirInscriptionUtilisateurConnecte(this._inscriptionRepository);

  final InscriptionRepository _inscriptionRepository;

  Future<Inscription?> executer({required Competition competition}) {
    final competitionId = competition.id.trim();

    if (competitionId.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    return _inscriptionRepository.obtenirInscriptionUtilisateurConnecte(
      competitionId: competitionId,
    );
  }
}
