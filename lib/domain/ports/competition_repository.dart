import '../entities/competition.dart';

abstract interface class CompetitionRepository {
  /// Récupère les compétitions visibles par l’utilisateur connecté.
  Future<List<Competition>> obtenirToutes();

  /// Récupère une compétition à partir de son identifiant.
  Future<Competition?> obtenirParId(String id);

  /// Enregistre une nouvelle compétition.
  Future<Competition> creer(Competition competition);

  /// Enregistre les modifications d’une compétition existante.
  Future<Competition> modifier(Competition competition);

  /// Récupère toutes les compétitions ouvertes aux inscriptions.
  Future<List<Competition>> obtenirOuvertes();

  /// Supprime une compétition.
  Future<void> supprimer(String id);
}
