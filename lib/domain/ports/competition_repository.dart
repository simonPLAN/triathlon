import '../entities/competition.dart';
import '../entities/fichier_affiche_epreuve.dart';

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

  /// Enregistre ou remplace l’image de couverture d’une compétition.
  Future<Competition> enregistrerImage(
    Competition competition,
    FichierAfficheEpreuve fichier,
  );

  /// Supprime l’image de couverture d’une compétition.
  Future<Competition> supprimerImage(Competition competition);

  /// Supprime une compétition.
  Future<void> supprimer(String id);
}
