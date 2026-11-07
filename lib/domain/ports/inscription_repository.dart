import '../entities/inscription.dart';

abstract interface class InscriptionRepository {
  /// Récupère les inscriptions d’une compétition.
  Future<List<Inscription>> obtenirParCompetition(String competitionId);

  /// Inscrit un athlète à une compétition.
  Future<Inscription> inscrire({
    required String competitionId,
    required String athleteId,
    int? numeroDossard,
  });

  /// Modifie le numéro de dossard d’une inscription.
  Future<Inscription> modifierNumeroDossard({
    required String inscriptionId,
    int? numeroDossard,
  });

  /// Inscrit l’athlète actuellement connecté.
  Future<Inscription> inscrireUtilisateurConnecte({
    required String competitionId,
  });

  /// Récupère l’inscription de l’utilisateur connecté
  /// pour une compétition.
  Future<Inscription?> obtenirInscriptionUtilisateurConnecte({
    required String competitionId,
  });

  /// Désinscrit un athlète d’une compétition.
  Future<void> desinscrire(String inscriptionId);
}
