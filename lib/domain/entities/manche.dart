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
    this.revisionResultats = 0,
    this.participantsDefinis = false,
    this.participantsAthleteIds = const [],
    this.dureeLimiteSecondes,
    this.validationRequise = false,
    this.revisionValidationResultats,
  });

  final String id;
  final String epreuveId;
  final int numero;
  final StatutManche statut;

  final DateTime? heureDepart;
  final DateTime? heurePremiereArrivee;
  final DateTime? heureFinDelai;

  final bool resultatsPublies;
  final bool validationRequise;
  final int? revisionValidationResultats;
  bool get resultatsValides =>
      resultatsPublies ||
      (revisionValidationResultats != null &&
          revisionValidationResultats == revisionResultats);
  final int revisionResultats;
  final bool participantsDefinis;

  /// Identifiants dans l’ordre de départ, distinct de l’ordre d’arrivée.
  final List<String> participantsAthleteIds;
  final int? dureeLimiteSecondes;

  bool contientParticipant(String athleteId) =>
      !participantsDefinis || participantsAthleteIds.contains(athleteId);

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
    return estTerminee &&
        !resultatsPublies &&
        (!validationRequise || resultatsValides);
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

    final heureDepartUtc = heureDepart!.toUtc();
    final heureArriveeUtc = heureArrivee.toUtc();
    if (heureArriveeUtc.isBefore(heureDepartUtc)) {
      throw ArgumentError(
        'L’heure d’arrivée ne peut pas précéder l’heure de départ. '
        'Vérifie les horaires enregistrés et l’horloge de l’appareil.',
      );
    }
    final heureArriveeEffective = heureArriveeUtc;

    return copierAvec(
      heurePremiereArrivee: heureArriveeEffective.toLocal(),
      heureFinDelai: heureArriveeEffective.toLocal().add(
        Duration(seconds: dureeLimiteSecondes),
      ),
      dateModification: DateTime.now(),
    );
  }

  Manche terminer({required DateTime heure}) {
    if (!estEnCours) {
      throw StateError('Seule une manche en cours peut être terminée.');
    }

    final heureDepartActuelle = heureDepart;

    if (heureDepartActuelle == null) {
      throw StateError('La manche ne possède pas d’heure de départ.');
    }

    final heureFinUtc = heure.toUtc();
    final heureDepartUtc = heureDepartActuelle.toUtc();

    if (heureFinUtc.isBefore(heureDepartUtc)) {
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

    if (validationRequise && !resultatsValides) {
      throw StateError('Valide le classement avant publication.');
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
    int? revisionResultats,
    bool? participantsDefinis,
    List<String>? participantsAthleteIds,
    int? dureeLimiteSecondes,
    bool? validationRequise,
    int? revisionValidationResultats,
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
      revisionResultats: revisionResultats ?? this.revisionResultats,
      participantsDefinis: participantsDefinis ?? this.participantsDefinis,
      participantsAthleteIds:
          participantsAthleteIds ?? this.participantsAthleteIds,
      dureeLimiteSecondes: dureeLimiteSecondes ?? this.dureeLimiteSecondes,
      validationRequise: validationRequise ?? this.validationRequise,
      revisionValidationResultats:
          revisionValidationResultats ?? this.revisionValidationResultats,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
