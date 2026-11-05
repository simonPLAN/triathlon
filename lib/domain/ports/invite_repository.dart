import '../entities/inscription.dart';

abstract interface class InviteRepository {
  Future<Inscription> inscrire({
    required String competitionId,
    required String pseudo,
    int? numeroDossard,
  });
}
