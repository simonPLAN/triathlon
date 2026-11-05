import '../entities/manche.dart';
import '../entities/statut_resultat.dart';

abstract interface class CycleMancheRepository {
  /// Clôture les absents et démarre la prochaine manche configurée dans une transaction.
  /// Renvoie la manche suivante si elle a démarré, sinon celle qui vient de finir.
  Future<Manche> cloturerDelai(String mancheId);
  Future<Manche> validerResultats(String mancheId, int revision);
  Future<void> declarerStatut({
    required String mancheId,
    required String athleteId,
    required StatutResultat statut,
    required String motif,
  });
}
