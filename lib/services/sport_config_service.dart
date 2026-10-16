import '../constants/sports.dart';
import '../models/sport_config.dart';

class SportConfigService {
  final Map<String, SportConfig> _configs = {
    'Natation': SportConfig(
      rounds: 9,
      durationSeconds: 180,
      restSeconds: 90,
      pointsByPosition: [5, 4, 3, 2, 1],
    ),
    'Vélo': SportConfig(
      rounds: 3,
      durationSeconds: 180,
      restSeconds: 90,
      pointsByPosition: [5, 4, 3, 2, 1],
    ),
    'Course à pied': SportConfig(
      rounds: 2,
      durationSeconds: 180,
      restSeconds: 90,
      pointsByPosition: [5, 4, 3, 2, 1],
    ),
  };

  SportConfig config(String sport) {
    final result = _configs[sport];

    if (result == null) {
      throw StateError(
        'Configuration introuvable pour "$sport". '
        'Sports disponibles : ${_configs.keys.join(", ")}',
      );
    }

    return result;
  }

  void updateConfig(
    String sport, {
    required int rounds,
    required int durationSeconds,
    required int restSeconds,
    required List<int> pointsByPosition,
  }) {
    if (!sports.contains(sport)) {
      throw ArgumentError('Sport inconnu : $sport');
    }

    _configs[sport] = SportConfig(
      rounds: rounds.clamp(1, 100),
      durationSeconds: durationSeconds.clamp(1, 86400),
      restSeconds: restSeconds.clamp(0, 86400),
      pointsByPosition: pointsByPosition,
    );
  }

  void restoreFromJson(Map<String, dynamic>? savedConfigs) {
    if (savedConfigs != null) {
      for (final sport in sports) {
        final saved = savedConfigs[sport];
        if (saved is Map) {
          _configs[sport] = SportConfig.fromJson(
            Map<String, dynamic>.from(saved),
          );
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      for (final entry in _configs.entries) entry.key: entry.value.toJson(),
    };
  }
}
