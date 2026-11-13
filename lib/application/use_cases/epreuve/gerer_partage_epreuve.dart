import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/partage_epreuve.dart';
import '../../../domain/ports/partage_epreuve_repository.dart';

class GererPartageEpreuve {
  GererPartageEpreuve(this._repository);
  final PartageEpreuveRepository _repository;

  String _id(String valeur) {
    if (valeur.trim().isEmpty) {
      throw ArgumentError('L’identifiant est obligatoire.');
    }
    return valeur.trim();
  }

  Future<List<CoachAutoriseEpreuve>> listerCoachs(String epreuveId) =>
      _repository.listerCoachs(_id(epreuveId));

  Future<void> autoriser(String epreuveId, String pseudo) {
    final id = _id(epreuveId);
    final valeur = pseudo.trim();
    if (valeur.isEmpty || valeur.length > 80) {
      throw ArgumentError('Renseigne le pseudo du coach.');
    }
    return _repository.autoriser(id, valeur);
  }

  Future<void> retirer(String epreuveId, String coachId) =>
      _repository.retirer(_id(epreuveId), _id(coachId));

  Future<List<EpreuvePartagee>> listerPartagees() =>
      _repository.listerPartagees();

  Future<List<Inscription>> listerParticipants(String mancheId) =>
      _repository.listerParticipants(_id(mancheId));
}
