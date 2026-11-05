import '../../../domain/entities/resultat.dart';
import '../../../domain/ports/resultat_repository.dart';

class ListerResultatsManche {
  ListerResultatsManche(this._resultatRepository);

  final ResultatRepository _resultatRepository;

  Future<List<Resultat>> executer(String mancheId) async {
    final idNettoye = mancheId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    final resultats = await _resultatRepository.obtenirParManche(idNettoye);

    final resultatsTries = [...resultats]..sort(_comparerResultats);

    return List.unmodifiable(resultatsTries);
  }

  int _comparerResultats(Resultat resultatA, Resultat resultatB) {
    final positionA = resultatA.position;
    final positionB = resultatB.position;

    // Les athlètes avec une position passent en premier.
    if (positionA != null && positionB == null) {
      return -1;
    }

    if (positionA == null && positionB != null) {
      return 1;
    }

    // Deux athlètes arrivés sont classés par position.
    if (positionA != null && positionB != null) {
      final comparaisonPosition = positionA.compareTo(positionB);

      if (comparaisonPosition != 0) {
        return comparaisonPosition;
      }
    }

    // Les résultats sans position sont classés par nom.
    final comparaisonNom = resultatA.athlete.nom.toLowerCase().compareTo(
      resultatB.athlete.nom.toLowerCase(),
    );

    if (comparaisonNom != 0) {
      return comparaisonNom;
    }

    return resultatA.athlete.prenom.toLowerCase().compareTo(
      resultatB.athlete.prenom.toLowerCase(),
    );
  }
}
