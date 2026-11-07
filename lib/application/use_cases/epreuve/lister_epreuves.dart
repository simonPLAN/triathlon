import '../../../domain/entities/epreuve.dart';
import '../../../domain/ports/epreuve_repository.dart';

class ListerEpreuves {
  ListerEpreuves(this._epreuveRepository);

  final EpreuveRepository _epreuveRepository;

  Future<List<Epreuve>> executer(String competitionId) async {
    final idNettoye = competitionId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    final epreuves = await _epreuveRepository.obtenirParCompetition(idNettoye);

    final epreuvesTriees = [...epreuves];

    epreuvesTriees.sort((epreuveA, epreuveB) {
      final comparaisonOrdre = epreuveA.ordre.compareTo(epreuveB.ordre);

      if (comparaisonOrdre != 0) {
        return comparaisonOrdre;
      }

      return epreuveA.nom.toLowerCase().compareTo(epreuveB.nom.toLowerCase());
    });

    return List.unmodifiable(epreuvesTriees);
  }
}
