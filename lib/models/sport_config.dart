class SportConfig {
  int rounds;
  int durationSeconds;
  int restSeconds;
  List<int> pointsByPosition;

  SportConfig({
    required this.rounds,
    required this.durationSeconds,
    required this.restSeconds,
    this.pointsByPosition = const [5, 4, 3, 2, 1],
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
      pointsList = const [5, 4, 3, 2, 1];
    }

    return SportConfig(
      rounds: ((json['rounds'] as num?)?.toInt() ?? 1).clamp(1, 100),
      durationSeconds:
          ((json['durationSeconds'] as num?)?.toInt() ?? 180).clamp(0, 86400),
      restSeconds:
          ((json['restSeconds'] as num?)?.toInt() ?? 90).clamp(0, 86400),
      pointsByPosition: pointsList,
    );
  }
}
