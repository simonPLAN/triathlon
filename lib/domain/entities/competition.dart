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

  static const _nonRenseigne = Object();

  bool get estEnCours {
    return statut == StatutCompetition.enCours;
  }

  bool get estTerminee {
    return statut == StatutCompetition.terminee;
  }

  bool get estAnnulee {
    return statut == StatutCompetition.annulee;
  }

  Competition ouvrir() {
    if (statut != StatutCompetition.brouillon) {
      throw StateError('Seule une compétition en brouillon peut être ouverte.');
    }

    return copierAvec(
      statut: StatutCompetition.ouverte,
      dateModification: DateTime.now(),
    );
  }

  Competition demarrer() {
    if (statut != StatutCompetition.ouverte) {
      throw StateError('Seule une compétition ouverte peut être démarrée.');
    }

    return copierAvec(
      statut: StatutCompetition.enCours,
      dateModification: DateTime.now(),
    );
  }

  Competition terminer() {
    if (statut != StatutCompetition.enCours) {
      throw StateError('Seule une compétition en cours peut être terminée.');
    }

    return copierAvec(
      statut: StatutCompetition.terminee,
      dateModification: DateTime.now(),
    );
  }

  Competition annuler() {
    if (statut == StatutCompetition.terminee) {
      throw StateError('Une compétition terminée ne peut plus être annulée.');
    }

    if (statut == StatutCompetition.annulee) {
      throw StateError('Cette compétition est déjà annulée.');
    }

    return copierAvec(
      statut: StatutCompetition.annulee,
      dateModification: DateTime.now(),
    );
  }

  Competition copierAvec({
    String? id,
    String? nom,
    Object? description = _nonRenseigne,
    Object? lieu = _nonRenseigne,
    DateTime? dateCompetition,
    StatutCompetition? statut,
    String? coachId,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Competition(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: identical(description, _nonRenseigne)
          ? this.description
          : description as String?,
      lieu: identical(lieu, _nonRenseigne) ? this.lieu : lieu as String?,
      dateCompetition: dateCompetition ?? this.dateCompetition,
      statut: statut ?? this.statut,
      coachId: coachId ?? this.coachId,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
