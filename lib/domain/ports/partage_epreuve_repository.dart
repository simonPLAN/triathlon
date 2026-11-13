import '../entities/inscription.dart';
import '../entities/partage_epreuve.dart';

abstract interface class PartageEpreuveRepository {
  Future<List<CoachAutoriseEpreuve>> listerCoachs(String epreuveId);
  Future<void> autoriser(String epreuveId, String pseudo);
  Future<void> retirer(String epreuveId, String coachId);
  Future<List<EpreuvePartagee>> listerPartagees();
  Future<List<Inscription>> listerParticipants(String mancheId);
}
