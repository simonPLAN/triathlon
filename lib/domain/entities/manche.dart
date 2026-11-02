import 'statut_manche.dart';

class Manche {
  const Manche({
    required this.id,
    required this.epreuveId,
    required this.numero,
    required this.statut,
    required this.resultatsPublies,
    required this.dateCreation,
    required this.dateModification,
    this.heureDepart,
    this.heurePremiereArrivee,
    this.heureFinDelai,
  });

  final String id;
  final String epreuveId;
  final int numero;
  final StatutManche statut;

  final DateTime? heureDepart;
  final DateTime? heurePremiereArrivee;
  final DateTime? heureFinDelai;

  final bool resultatsPublies;

  final DateTime dateCreation;
  final DateTime dateModification;

  bool get estAVenir {
    return statut == StatutManche.aVenir;
  }

  bool get estEnCours {
    return statut == StatutManche.enCours;
  }

  bool get estTerminee {
    return statut == StatutManche.terminee;
  }

  bool get estAnnulee {
    return statut == StatutManche.annulee;
  }

  bool get premierArrive {
    return heurePremiereArrivee != null;
  }

  bool get delaiDemarre {
    return heurePremiereArrivee != null && heureFinDelai != null;
  }

  bool get peutPublierResultats {
    return estTerminee && !resultatsPublies;
  }

  Manche demarrer({required DateTime heure}) {
    if (!estAVenir) {
      throw StateError('Seule une manche à venir peut être démarrée.');
    }

    return copierAvec(
      statut: StatutManche.enCours,
      heureDepart: heure,
      dateModification: DateTime.now(),
    );
  }

  Manche enregistrerPremiereArrivee({
    required DateTime heureArrivee,
    required int dureeLimiteSecondes,
  }) {
    if (!estEnCours) {
      throw StateError(
        'La première arrivée ne peut être enregistrée '
        'que pendant une manche en cours.',
      );
    }

    if (heureDepart == null) {
      throw StateError('La manche doit avoir une heure de départ.');
    }

    if (heurePremiereArrivee != null) {
      throw StateError('La première arrivée a déjà été enregistrée.');
    }

    if (dureeLimiteSecondes <= 0) {
      throw ArgumentError('La durée limite doit être supérieure à zéro.');
    }

    if (heureArrivee.isBefore(heureDepart!)) {
      throw ArgumentError(
        'L’heure d’arrivée ne peut pas précéder '
        'l’heure de départ.',
      );
    }

    return copierAvec(
      heurePremiereArrivee: heureArrivee,
      heureFinDelai: heureArrivee.add(Duration(seconds: dureeLimiteSecondes)),
      dateModification: DateTime.now(),
    );
  }

  Manche terminer({required DateTime heure}) {
    if (!estEnCours) {
      throw StateError('Seule une manche en cours peut être terminée.');
    }

    if (heureDepart != null && heure.isBefore(heureDepart!)) {
      throw ArgumentError(
        'L’heure de fin ne peut pas précéder '
        'l’heure de départ.',
      );
    }

    return copierAvec(
      statut: StatutManche.terminee,
      dateModification: DateTime.now(),
    );
  }

  Manche annuler() {
    if (estTerminee) {
      throw StateError('Une manche terminée ne peut pas être annulée.');
    }

    if (estAnnulee) {
      throw StateError('Cette manche est déjà annulée.');
    }

    return copierAvec(
      statut: StatutManche.annulee,
      dateModification: DateTime.now(),
    );
  }

  Manche publierResultats() {
    if (!estTerminee) {
      throw StateError(
        'Les résultats ne peuvent être publiés '
        'que lorsque la manche est terminée.',
      );
    }

    if (resultatsPublies) {
      throw StateError('Les résultats sont déjà publiés.');
    }

    return copierAvec(resultatsPublies: true, dateModification: DateTime.now());
  }

  Manche copierAvec({
    String? id,
    String? epreuveId,
    int? numero,
    StatutManche? statut,
    DateTime? heureDepart,
    DateTime? heurePremiereArrivee,
    DateTime? heureFinDelai,
    bool? resultatsPublies,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Manche(
      id: id ?? this.id,
      epreuveId: epreuveId ?? this.epreuveId,
      numero: numero ?? this.numero,
      statut: statut ?? this.statut,
      heureDepart: heureDepart ?? this.heureDepart,
      heurePremiereArrivee: heurePremiereArrivee ?? this.heurePremiereArrivee,
      heureFinDelai: heureFinDelai ?? this.heureFinDelai,
      resultatsPublies: resultatsPublies ?? this.resultatsPublies,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
