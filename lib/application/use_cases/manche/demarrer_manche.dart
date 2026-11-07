import '../../../domain/entities/manche.dart';
import '../../../domain/ports/manche_repository.dart';

class DemarrerManche {
  DemarrerManche(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<Manche> executer(Manche manche, {DateTime? heureDepart}) {
    if (manche.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    final mancheDemarree = manche.demarrer(
      heure: heureDepart ?? DateTime.now(),
    );

    return _mancheRepository.modifier(mancheDemarree);
  }
}
