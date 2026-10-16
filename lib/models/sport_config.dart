import '../constants/sports.dart';

class SportConfig {
  int rounds;
  int durationSeconds;
  int restSeconds;
  List<int> pointsByPosition;

  SportConfig({
    required this.rounds,
    required this.durationSeconds,
    required this.restSeconds,
    this.pointsByPosition = defaultPointsByPosition,
  });

  Map<String, dynamic> toJson() => {
        'rounds': rounds,
        'durationSeconds': durationSeconds,
        'restSeconds': restSeconds,
        'pointsByPosition': pointsByPosition,
      };

  factory SportConfig.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['pointsByPosition'];
    List<int> pointsList;
    if (rawPoints is List && rawPoints.isNotEmpty) {
      pointsList = rawPoints.map((e) => (e as num).toInt()).toList();
    } else {
      pointsList = defaultPointsByPosition;
    }

    return SportConfig(
      rounds: ((json['rounds'] as num?)?.toInt() ?? defaultRounds)
          .clamp(minRounds, maxRounds),
      durationSeconds:
          ((json['durationSeconds'] as num?)?.toInt() ?? defaultDurationSeconds)
              .clamp(minDurationSeconds, maxDurationSeconds),
      restSeconds:
          ((json['restSeconds'] as num?)?.toInt() ?? defaultRestSeconds)
              .clamp(minRestSeconds, maxRestSeconds),
      pointsByPosition: pointsList,
    );
  }
}
