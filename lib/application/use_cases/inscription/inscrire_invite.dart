import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/invite_repository.dart';

class InscrireInvite {
  InscrireInvite(this._repository);
  final InviteRepository _repository;

  Future<Inscription> executer({
    required Competition competition,
    required String prenom,
    required String nom,
    int? numeroDossard,
  }) {
    if (!competition.estBrouillon && !competition.estOuverte) {
      throw StateError('Les inscriptions sont fermées.');
    }
    if (prenom.trim().isEmpty || nom.trim().isEmpty) {
      throw ArgumentError('Le prénom et le nom sont obligatoires.');
    }
    if (prenom.trim().length > 100 || nom.trim().length > 100) {
      throw ArgumentError('Le prénom et le nom sont limités à 100 caractères.');
    }
    if (numeroDossard != null && numeroDossard <= 0) {
      throw ArgumentError('Le dossard doit être supérieur à zéro.');
    }
    return _repository.inscrire(
      competitionId: competition.id,
      prenom: prenom.trim(),
      nom: nom.trim(),
      numeroDossard: numeroDossard,
    );
  }
}
