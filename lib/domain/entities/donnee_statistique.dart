/// Une observation réelle, pour une seule paire athlète/manche.
class DonneeStatistique {
  const DonneeStatistique({
    required this.athleteId,
    required this.nomAthlete,
    required this.epreuveId,
    required this.nomEpreuve,
    required this.mancheId,
    required this.numeroManche,
    required this.points,
    required this.statut,
    this.tempsMillisecondes,
    this.coefficient,
  });
  final String athleteId, nomAthlete, epreuveId, nomEpreuve, mancheId;
  final int numeroManche, points;
  final String statut;
  final int? tempsMillisecondes;
  final double? coefficient;
}
