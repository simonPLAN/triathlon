import '../constants/sports.dart';
import '../models/sport_config.dart';

class SportConfigService {
  final Map<String, SportConfig> _configs = {
    sportNatation: SportConfig(
      rounds: defaultNatationRounds,
      durationSeconds: defaultDurationSeconds,
      restSeconds: defaultRestSeconds,
      pointsByPosition: defaultPointsByPosition,
    ),
    sportVelo: SportConfig(
      rounds: defaultVeloRounds,
      durationSeconds: defaultDurationSeconds,
      restSeconds: defaultRestSeconds,
      pointsByPosition: defaultPointsByPosition,
    ),
    sportCourse: SportConfig(
      rounds: defaultCourseRounds,
      durationSeconds: defaultDurationSeconds,
      restSeconds: defaultRestSeconds,
      pointsByPosition: defaultPointsByPosition,
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
      rounds: rounds.clamp(minRounds, maxRounds),
      durationSeconds: durationSeconds.clamp(minDurationSeconds, maxDurationSeconds),
      restSeconds: restSeconds.clamp(minRestSeconds, maxRestSeconds),
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
