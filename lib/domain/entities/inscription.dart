import 'athlete.dart';

class Inscription {
  const Inscription({
    required this.id,
    required this.competitionId,
    required this.athlete,
    required this.dateInscription,
    this.numeroDossard,
  });

  final String id;
  final String competitionId;
  final Athlete athlete;
  final int? numeroDossard;
  final DateTime dateInscription;

  bool get possedeDossard {
    return numeroDossard != null;
  }

  Inscription copierAvec({
    String? id,
    String? competitionId,
    Athlete? athlete,
    int? numeroDossard,
    DateTime? dateInscription,
  }) {
    return Inscription(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      athlete: athlete ?? this.athlete,
      numeroDossard: numeroDossard ?? this.numeroDossard,
      dateInscription: dateInscription ?? this.dateInscription,
    );
  }
}
