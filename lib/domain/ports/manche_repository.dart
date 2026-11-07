import '../entities/manche.dart';

abstract interface class MancheRepository {
  /// Récupère toutes les manches d’une épreuve.
  Future<List<Manche>> obtenirParEpreuve(String epreuveId);

  /// Récupère une manche par son identifiant.
  Future<Manche?> obtenirParId(String id);

  /// Crée plusieurs manches pour une épreuve.
  Future<List<Manche>> creerPlusieurs(List<Manche> manches);

  /// Enregistre les modifications d’une manche.
  Future<Manche> modifier(Manche manche);

  /// Supprime toutes les manches d’une épreuve.
  Future<void> supprimerParEpreuve(String epreuveId);
}
