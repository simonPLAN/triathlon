import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/statut_manche.dart';
import '../../../domain/ports/manche_repository.dart';

class GenererManchesPourEpreuve {
  GenererManchesPourEpreuve(this._mancheRepository);

  final MancheRepository _mancheRepository;

  Future<List<Manche>> executer(Epreuve epreuve) async {
    if (epreuve.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    if (epreuve.nombreManches <= 0) {
      throw ArgumentError('Le nombre de manches doit être supérieur à zéro.');
    }

    final manchesExistantes = await _mancheRepository.obtenirParEpreuve(
      epreuve.id,
    );

    if (manchesExistantes.isNotEmpty) {
      throw StateError('Les manches de cette épreuve ont déjà été générées.');
    }

    final maintenant = DateTime.now();

    final manches = List<Manche>.generate(epreuve.nombreManches, (index) {
      return Manche(
        id: '',
        epreuveId: epreuve.id,
        numero: index + 1,
        statut: StatutManche.aVenir,
        resultatsPublies: false,
        dateCreation: maintenant,
        dateModification: maintenant,
      );
    }, growable: false);

    return _mancheRepository.creerPlusieurs(manches);
  }
}
