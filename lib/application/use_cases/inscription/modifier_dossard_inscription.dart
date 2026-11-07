import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/inscription_repository.dart';

class ModifierDossardInscription {
  ModifierDossardInscription(this._inscriptionRepository);

  final InscriptionRepository _inscriptionRepository;

  Future<Inscription> executer({
    required String inscriptionId,
    int? numeroDossard,
  }) {
    final inscriptionIdNettoye = inscriptionId.trim();

    if (inscriptionIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’inscription est obligatoire.');
    }

    if (numeroDossard != null && numeroDossard <= 0) {
      throw ArgumentError('Le numéro de dossard doit être supérieur à zéro.');
    }

    return _inscriptionRepository.modifierNumeroDossard(
      inscriptionId: inscriptionIdNettoye,
      numeroDossard: numeroDossard,
    );
  }
}
