import 'athlete.dart';
import 'statut_resultat.dart';

class Resultat {
  const Resultat({
    required this.id,
    required this.mancheId,
    required this.athlete,
    required this.points,
    required this.statut,
    required this.dateCreation,
    required this.dateModification,
    this.position,
    this.heureArrivee,
    this.tempsTotalMillisecondes,
    this.ecartPremierMillisecondes,
    this.commentaire,
    this.datePublication,
  });

  final String id;
  final String mancheId;
  final Athlete athlete;

  /// La position reste nulle pour un athlète hors délai,
  /// ayant abandonné ou ayant été disqualifié.
  final int? position;

  final int points;
  final DateTime? heureArrivee;
  final int? tempsTotalMillisecondes;
  final int? ecartPremierMillisecondes;

  final StatutResultat statut;
  final String? commentaire;

  final DateTime? datePublication;
  final DateTime dateCreation;
  final DateTime dateModification;

  bool get estArrive {
    return statut == StatutResultat.arrive;
  }

  bool get estHorsDelai {
    return statut == StatutResultat.horsDelai;
  }

  bool get estAbandon {
    return statut == StatutResultat.abandon;
  }

  bool get estDisqualifie {
    return statut == StatutResultat.disqualifie;
  }

  bool get estPublie {
    return datePublication != null;
  }

  Resultat copierAvec({
    String? id,
    String? mancheId,
    Athlete? athlete,
    int? position,
    bool supprimerPosition = false,
    int? points,
    DateTime? heureArrivee,
    bool supprimerHeureArrivee = false,
    int? tempsTotalMillisecondes,
    bool supprimerTempsTotal = false,
    int? ecartPremierMillisecondes,
    bool supprimerEcartPremier = false,
    StatutResultat? statut,
    String? commentaire,
    bool supprimerCommentaire = false,
    DateTime? datePublication,
    bool supprimerDatePublication = false,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Resultat(
      id: id ?? this.id,
      mancheId: mancheId ?? this.mancheId,
      athlete: athlete ?? this.athlete,
      position: supprimerPosition ? null : position ?? this.position,
      points: points ?? this.points,
      heureArrivee: supprimerHeureArrivee
          ? null
          : heureArrivee ?? this.heureArrivee,
      tempsTotalMillisecondes: supprimerTempsTotal
          ? null
          : tempsTotalMillisecondes ?? this.tempsTotalMillisecondes,
      ecartPremierMillisecondes: supprimerEcartPremier
          ? null
          : ecartPremierMillisecondes ?? this.ecartPremierMillisecondes,
      statut: statut ?? this.statut,
      commentaire: supprimerCommentaire
          ? null
          : commentaire ?? this.commentaire,
      datePublication: supprimerDatePublication
          ? null
          : datePublication ?? this.datePublication,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
