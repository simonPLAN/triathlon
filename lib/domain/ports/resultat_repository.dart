import '../entities/resultat.dart';

abstract interface class ResultatRepository {
  /// Récupère tous les résultats d’une manche.
  Future<List<Resultat>> obtenirParManche(String mancheId);

  /// Récupère le résultat d’un athlète pour une manche.
  Future<Resultat?> obtenirParAthleteEtManche({
    required String mancheId,
    required String athleteId,
  });

  /// Enregistre un nouveau résultat.
  Future<Resultat> enregistrer(Resultat resultat);

  /// Modifie ou corrige un résultat existant.
  Future<Resultat> modifier(Resultat resultat);

  /// Enregistre plusieurs résultats simultanément.
  ///
  /// Cette méthode servira notamment à attribuer
  /// automatiquement zéro point aux athlètes hors délai.
  Future<List<Resultat>> enregistrerPlusieurs(List<Resultat> resultats);

  /// Supprime un résultat.
  Future<void> supprimer(String resultatId);
}
