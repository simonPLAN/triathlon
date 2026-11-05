class ClassementGlobalAthlete {
  const ClassementGlobalAthlete({
    required this.athleteId,
    required this.nom,
    required this.points,
    required this.nombreManches,
    required this.rang,
  });

  final String athleteId;
  final String nom;
  final int points;
  final int nombreManches;
  final int rang;
}
