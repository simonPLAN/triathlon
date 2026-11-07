class GroupeAthletes {
  GroupeAthletes({
    required this.id,
    required this.nom,
    required Iterable<String> athleteIds,
  }) : athleteIds = Set.unmodifiable(athleteIds);

  final String id;
  final String nom;
  final Set<String> athleteIds;

  int get nombreAthletes => athleteIds.length;
}
