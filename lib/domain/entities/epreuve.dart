import 'type_discipline.dart';

class Epreuve {
  const Epreuve({
    required this.id,
    required this.competitionId,
    required this.discipline,
    required this.nom,
    required this.distanceMetres,
    required this.nombreManches,
    required this.ordre,
    required this.dureeLimiteSecondes,
    required this.dateCreation,
    required this.dateModification,
  });

  final String id;
  final String competitionId;
  final TypeDiscipline discipline;
  final String nom;
  final int distanceMetres;
  final int nombreManches;
  final int ordre;
  final int dureeLimiteSecondes;
  final DateTime dateCreation;
  final DateTime dateModification;

  Epreuve copierAvec({
    String? id,
    String? competitionId,
    TypeDiscipline? discipline,
    String? nom,
    int? distanceMetres,
    int? nombreManches,
    int? ordre,
    int? dureeLimiteSecondes,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Epreuve(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      discipline: discipline ?? this.discipline,
      nom: nom ?? this.nom,
      distanceMetres: distanceMetres ?? this.distanceMetres,
      nombreManches: nombreManches ?? this.nombreManches,
      ordre: ordre ?? this.ordre,
      dureeLimiteSecondes: dureeLimiteSecondes ?? this.dureeLimiteSecondes,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
