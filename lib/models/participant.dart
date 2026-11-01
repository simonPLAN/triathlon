class Participant {
  final String name;
  final double coefficient;

  const Participant({
    required this.name,
    this.coefficient = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'coefficient': coefficient,
      };

  factory Participant.fromJson(dynamic json) {
    if (json is String) {
      return Participant(name: json, coefficient: 1.0);
    }
    if (json is Map) {
      return Participant(
        name: (json['name'] ?? json['nom'] ?? '') as String,
        coefficient:
            (json['coefficient'] ?? json['coef'] as num?)?.toDouble() ?? 1.0,
      );
    }
    return const Participant(name: '', coefficient: 1.0);
  }

  Participant copyWith({
    String? name,
    double? coefficient,
  }) {
    return Participant(
      name: name ?? this.name,
      coefficient: coefficient ?? this.coefficient,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          coefficient == other.coefficient;

  @override
  int get hashCode => name.hashCode ^ coefficient.hashCode;
}
