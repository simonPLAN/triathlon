import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/inscription_repository.dart';

class ListerInscriptions {
  ListerInscriptions(this._inscriptionRepository);

  final InscriptionRepository _inscriptionRepository;

  Future<List<Inscription>> executer({required String competitionId}) {
    final idNettoye = competitionId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    return _inscriptionRepository.obtenirParCompetition(idNettoye);
  }
}
