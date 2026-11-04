import '../../../domain/entities/manche.dart';
import '../../../domain/ports/configuration_manche_repository.dart';

class ConfigurerManche {
  ConfigurerManche(this._repository);
  final ConfigurationMancheRepository _repository;

  Future<Manche> executer({
    required Manche manche,
    required List<String> athleteIds,
    required int dureeLimiteSecondes,
  }) {
    if (!manche.estAVenir) {
      throw StateError('Les participants et le délai sont figés après le départ.');
    }
    if (athleteIds.isEmpty || athleteIds.any((id) => id.trim().isEmpty) ||
        athleteIds.toSet().length != athleteIds.length) {
      throw ArgumentError('Choisis au moins un participant, sans doublon.');
    }
    if (dureeLimiteSecondes <= 0 || dureeLimiteSecondes > 86400) {
      throw ArgumentError('Le délai doit être compris entre 1 et 86400 secondes.');
    }
    return _repository.configurer(
      mancheId: manche.id, athleteIds: List.unmodifiable(athleteIds),
      dureeLimiteSecondes: dureeLimiteSecondes,
    );
  }
}
