import '../../../domain/entities/manche.dart';
import '../../../domain/ports/manche_repository.dart';

class AnnulerManche {
  AnnulerManche(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<Manche> executer(Manche manche) {
    if (manche.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    final mancheAnnulee = manche.annuler();

    return _mancheRepository.modifier(mancheAnnulee);
  }
}
