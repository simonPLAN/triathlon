import 'competition.dart';
import 'epreuve.dart';

class CoachAutoriseEpreuve {
  const CoachAutoriseEpreuve({required this.id, required this.pseudo});
  final String id;
  final String pseudo;
}

class EpreuvePartagee {
  const EpreuvePartagee({required this.epreuve, required this.competition});
  final Epreuve epreuve;
  final Competition competition;
}
