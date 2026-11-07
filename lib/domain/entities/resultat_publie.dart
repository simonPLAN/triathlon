class ResultatPublie {
  const ResultatPublie({
    required this.athleteId,
    required this.nomAthlete,
    required this.epreuveId,
    required this.nomEpreuve,
    required this.mancheId,
    required this.numeroManche,
    required this.position,
    required this.points,
    required this.statut,
    required this.tempsMillisecondes,
  });
  final String athleteId;
  final String nomAthlete;
  final String epreuveId;
  final String nomEpreuve;
  final String mancheId;
  final int numeroManche;
  final int? position;
  final int points;
  final String statut;
  final int? tempsMillisecondes;
}
