enum RoleUtilisateur { coach, athlete }

enum StatutCompetition { brouillon, ouverte, enCours, terminee, annulee }

enum Discipline { natation, velo, courseAPied }

enum StatutManche { aVenir, enCours, terminee, annulee }

enum StatutResultat { arrive, horsDelai, abandon, disqualifie }

class ProfilUtilisateur {
  const ProfilUtilisateur({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.role,
  });
  final String id, prenom, nom;
  final RoleUtilisateur role;
  String get nomComplet => '$prenom $nom';
  bool get estCoach => role == RoleUtilisateur.coach;
}

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
  final String id, nom, coachId;
  final String? description, lieu;
  final DateTime dateCompetition, dateCreation, dateModification;
  final StatutCompetition statut;
  bool get estBrouillon => statut == StatutCompetition.brouillon;
  bool get estOuverte => statut == StatutCompetition.ouverte;
}

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
  });
  final String id, competitionId, nom;
  final Discipline discipline;
  final int distanceMetres, nombreManches, ordre, dureeLimiteSecondes;
}

class Manche {
  const Manche({
    required this.id,
    required this.epreuveId,
    required this.numero,
    required this.statut,
    required this.resultatsPublies,
    this.heureDepart,
    this.heurePremiereArrivee,
    this.heureFinDelai,
  });
  final String id, epreuveId;
  final int numero;
  final StatutManche statut;
  final bool resultatsPublies;
  final DateTime? heureDepart, heurePremiereArrivee, heureFinDelai;
  bool get estAVenir => statut == StatutManche.aVenir;
  bool get estEnCours => statut == StatutManche.enCours;
  bool get estTerminee => statut == StatutManche.terminee;
}

class Inscription {
  const Inscription({
    required this.id,
    required this.competitionId,
    required this.athlete,
    required this.dateInscription,
    this.numeroDossard,
  });
  final String id, competitionId;
  final ProfilUtilisateur athlete;
  final int? numeroDossard;
  final DateTime dateInscription;
}

class Resultat {
  const Resultat({
    required this.id,
    required this.mancheId,
    required this.athlete,
    required this.points,
    required this.statut,
    this.position,
    this.heureArrivee,
  });
  final String id, mancheId;
  final ProfilUtilisateur athlete;
  final int? position;
  final int points;
  final StatutResultat statut;
  final DateTime? heureArrivee;
}
