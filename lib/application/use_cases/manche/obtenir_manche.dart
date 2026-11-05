import '../../../domain/entities/manche.dart';
import '../../../domain/ports/manche_repository.dart';

class ObtenirManche {
  ObtenirManche(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<Manche?> executer(String mancheId) {
    final idNettoye = mancheId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    return _mancheRepository.obtenirParId(idNettoye);
  }
}
