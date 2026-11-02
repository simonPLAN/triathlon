import 'statut_manche.dart';
import 'type_discipline.dart';

class ProgrammeCompetition {
  ProgrammeCompetition({
    required List<EpreuveProgramme> epreuves,
    this.affectationsDisponibles = false,
  }) : epreuves = List.unmodifiable(epreuves);
  final List<EpreuveProgramme> epreuves;
  final bool affectationsDisponibles;
}

class EpreuveProgramme {
  EpreuveProgramme({
    required this.id,
    required this.nom,
    required this.discipline,
    required this.distanceMetres,
    required this.ordre,
    required List<MancheProgramme> manches,
  }) : manches = List.unmodifiable(manches);
  final String id;
  final String nom;
  final TypeDiscipline discipline;
  final int distanceMetres;
  final int ordre;
  final List<MancheProgramme> manches;
}

class MancheProgramme {
  const MancheProgramme({
    required this.id,
    required this.numero,
    required this.statut,
    this.participe,
    this.ordreDepart,
  });
  final String id;
  final int numero;
  final StatutManche statut;

  /// null signifie inconnu ; l'inscription à la compétition ne vaut pas affectation.
  final bool? participe;
  final int? ordreDepart;
}
