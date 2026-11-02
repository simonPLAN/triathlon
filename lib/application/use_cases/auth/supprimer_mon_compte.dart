import '../../../domain/ports/suppression_compte_repository.dart';

class SupprimerMonCompte {
  const SupprimerMonCompte(this._repository);
  final SuppressionCompteRepository _repository;

  Future<void> executer({
    required String motDePasse,
    required bool confirmation,
  }) {
    if (!confirmation) {
      throw ArgumentError('Confirme la suppression de ton compte.');
    }
    if (motDePasse.isEmpty) {
      throw ArgumentError('Saisis ton mot de passe actuel.');
    }
    return _repository.supprimer(motDePasse);
  }

  Future<void> effacerSessionLocale() => _repository.effacerSessionLocale();
}
