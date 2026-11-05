import '../../../domain/entities/manche.dart';
import '../../../domain/ports/manche_repository.dart';

class TerminerManche {
  TerminerManche(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<Manche> executer(Manche manche, {DateTime? heureFin}) {
    if (manche.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    final mancheTerminee = manche.terminer(heure: heureFin ?? DateTime.now());

    return _mancheRepository.modifier(mancheTerminee);
  }
}
