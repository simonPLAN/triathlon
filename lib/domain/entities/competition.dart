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
    this.imageUrl,
    required this.demarrageAutomatiqueMancheSuivante,
  });

  final String id;
  final String nom;
  final String? description;
  final String? lieu;
  final Uri? imageUrl;
  final DateTime dateCompetition;
  final StatutCompetition statut;
  final String coachId;
  final DateTime dateCreation;
  final DateTime dateModification;
  final bool demarrageAutomatiqueMancheSuivante;

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

  Competition ouvrir() {
    if (statut != StatutCompetition.brouillon) {
      throw StateError('Seule une compétition en brouillon peut être ouverte.');
    }

    return copierAvec(
      statut: StatutCompetition.ouverte,
      dateModification: DateTime.now(),
    );
  }

  Competition repasserEnBrouillon() {
    if (statut != StatutCompetition.ouverte) {
      throw StateError(
        'Seule une compétition ouverte peut revenir en brouillon.',
      );
    }

    return copierAvec(
      statut: StatutCompetition.brouillon,
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
    String? description,
    String? lieu,
    Uri? imageUrl,
    bool supprimerImage = false,
    DateTime? dateCompetition,
    StatutCompetition? statut,
    String? coachId,
    bool? demarrageAutomatiqueMancheSuivante,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Competition(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      lieu: lieu ?? this.lieu,
      imageUrl: supprimerImage ? null : imageUrl ?? this.imageUrl,
      dateCompetition: dateCompetition ?? this.dateCompetition,
      statut: statut ?? this.statut,
      coachId: coachId ?? this.coachId,
      demarrageAutomatiqueMancheSuivante:
          demarrageAutomatiqueMancheSuivante ??
          this.demarrageAutomatiqueMancheSuivante,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
