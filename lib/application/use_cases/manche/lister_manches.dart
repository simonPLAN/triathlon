import '../../../domain/entities/manche.dart';
import '../../../domain/ports/manche_repository.dart';

class ListerManches {
  ListerManches(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<List<Manche>> executer(String epreuveId) async {
    final idNettoye = epreuveId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    final manches = await _mancheRepository.obtenirParEpreuve(idNettoye);

    final manchesTriees = [...manches]
      ..sort((mancheA, mancheB) {
        return mancheA.numero.compareTo(mancheB.numero);
      });

    return List.unmodifiable(manchesTriees);
  }
}
