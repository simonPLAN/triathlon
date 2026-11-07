import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/invite_repository.dart';

class InscrireInvite {
  InscrireInvite(this._repository);
  final InviteRepository _repository;

  Future<Inscription> executer({
    required Competition competition,
    required String pseudo,
    int? numeroDossard,
  }) {
    if (!competition.estBrouillon && !competition.estOuverte) {
      throw StateError('Les inscriptions sont fermées.');
    }
    final pseudoNettoye = pseudo.trim();
    if (!RegExp(r'^[A-Za-z0-9_.-]{3,30}$').hasMatch(pseudoNettoye)) {
      throw ArgumentError('Le pseudo doit contenir 3 à 30 caractères valides.');
    }
    if (numeroDossard != null && numeroDossard <= 0) {
      throw ArgumentError('Le dossard doit être supérieur à zéro.');
    }
    return _repository.inscrire(
      competitionId: competition.id,
      pseudo: pseudoNettoye,
      numeroDossard: numeroDossard,
    );
  }
}
