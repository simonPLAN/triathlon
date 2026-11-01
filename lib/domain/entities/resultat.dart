import 'athlete.dart';

class Resultat {
  const Resultat({
    required this.athlete,
    required this.position,
    required this.points,
  });

  final Athlete athlete;
  final int position;
  final int points;
}
