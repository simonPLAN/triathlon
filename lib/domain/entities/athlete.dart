class Athlete {
  const Athlete({required this.id, required this.prenom, required this.nom});

  final String id;
  final String prenom;
  final String nom;

  String get nomComplet => '$prenom $nom';
}
