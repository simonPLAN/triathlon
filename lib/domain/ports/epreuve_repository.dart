import '../entities/epreuve.dart';

abstract interface class EpreuveRepository {
  /// Récupère toutes les épreuves d’une compétition.
  Future<List<Epreuve>> obtenirParCompetition(String competitionId);

  /// Récupère une épreuve avec son identifiant.
  Future<Epreuve?> obtenirParId(String id);

  /// Crée une nouvelle épreuve.
  Future<Epreuve> creer(Epreuve epreuve);

  /// Modifie une épreuve existante.
  Future<Epreuve> modifier(Epreuve epreuve);

  /// Applique un ordre complet dans une seule transaction.
  Future<void> reordonner(String competitionId, List<String> epreuveIds);

  /// Supprime une épreuve.
  Future<void> supprimer(String id);
}
