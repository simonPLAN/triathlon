import '../../../domain/entities/manche.dart';
import '../../../domain/ports/manche_repository.dart';

class PublierResultatsManche {
  PublierResultatsManche(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<Manche> executer(Manche manche) {
    if (manche.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    final manchePubliee = manche.publierResultats();

    return _mancheRepository.modifier(manchePubliee);
  }
}
