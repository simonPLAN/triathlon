import '../../../domain/entities/manche.dart';
import '../../../domain/ports/manche_repository.dart';

class EnregistrerPremiereArrivee {
  EnregistrerPremiereArrivee(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<Manche> executer({
    required Manche manche,
    required int dureeLimiteSecondes,
    DateTime? heureArrivee,
  }) {
    if (manche.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    if (dureeLimiteSecondes <= 0) {
      throw ArgumentError('La durée limite doit être supérieure à zéro.');
    }

    final mancheActualisee = manche.enregistrerPremiereArrivee(
      heureArrivee: heureArrivee ?? DateTime.now(),
      dureeLimiteSecondes: dureeLimiteSecondes,
    );

    return _mancheRepository.modifier(mancheActualisee);
  }
}
