import '../entities/manche.dart';

abstract interface class ConfigurationMancheRepository {
  Future<Manche> configurer({
    required String mancheId,
    required List<String> athleteIds,
    required int dureeLimiteSecondes,
  });
}
