class SportConfig {
  int rounds;
  int durationSeconds;
  int restSeconds;

  SportConfig({
    required this.rounds,
    required this.durationSeconds,
    required this.restSeconds,
  });

  Map<String, dynamic> toJson() => {
        'rounds': rounds,
        'durationSeconds': durationSeconds,
        'restSeconds': restSeconds,
      };

  factory SportConfig.fromJson(Map<String, dynamic> json) {
    return SportConfig(
      rounds: ((json['rounds'] as num?)?.toInt() ?? 1).clamp(1, 100),
      durationSeconds:
          ((json['durationSeconds'] as num?)?.toInt() ?? 180).clamp(0, 86400),
      restSeconds:
          ((json['restSeconds'] as num?)?.toInt() ?? 90).clamp(0, 86400),
    );
  }
}
