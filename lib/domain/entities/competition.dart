import 'statut_competition.dart';

class Competition {
  const Competition({
    required this.id,
    required this.nom,
    required this.dateCompetition,
    required this.coachId,
    required this.statut,
    required this.dateCreation,
    required this.dateModification,
    this.description,
    this.lieu,
  });

  final String id;
  final String nom;
  final String? description;
  final String? lieu;
  final DateTime dateCompetition;
  final StatutCompetition statut;
  final String coachId;
  final DateTime dateCreation;
  final DateTime dateModification;

  bool get estBrouillon {
    return statut == StatutCompetition.brouillon;
  }

  bool get estOuverte {
    return statut == StatutCompetition.ouverte;
  }

  bool get estEnCours {
    return statut == StatutCompetition.enCours;
  }

  bool get estTerminee {
    return statut == StatutCompetition.terminee;
  }

  bool get estAnnulee {
    return statut == StatutCompetition.annulee;
  }

  Competition copierAvec({
    String? id,
    String? nom,
    String? description,
    String? lieu,
    DateTime? dateCompetition,
    StatutCompetition? statut,
    String? coachId,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Competition(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      lieu: lieu ?? this.lieu,
      dateCompetition: dateCompetition ?? this.dateCompetition,
      statut: statut ?? this.statut,
      coachId: coachId ?? this.coachId,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
