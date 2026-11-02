import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../../domain/ports/resultat_repository.dart';

class MarquerAthletesHorsDelai {
  MarquerAthletesHorsDelai(this._resultatRepository);

  final ResultatRepository _resultatRepository;

  Future<List<Resultat>> executer({
    required Manche manche,
    required List<Athlete> athletes,
    DateTime? maintenant,
  }) async {
    _verifierManche(manche);

    if (athletes.isEmpty) {
      return const [];
    }

    final instantActuel = maintenant ?? DateTime.now();

    final heureFinDelai = manche.heureFinDelai!;

    if (instantActuel.isBefore(heureFinDelai)) {
      throw StateError('Le délai de la manche n’est pas encore écoulé.');
    }

    final resultatsExistants = await _resultatRepository.obtenirParManche(
      manche.id,
    );

    final athleteIdsAvecResultat = resultatsExistants
        .map((resultat) => resultat.athlete.id)
        .toSet();

    final athletesSansResultat = athletes
        .where((athlete) {
          return !athleteIdsAvecResultat.contains(athlete.id);
        })
        .toList(growable: false);

    if (athletesSansResultat.isEmpty) {
      return const [];
    }

    final dateCreation = DateTime.now();

    final resultatsHorsDelai = athletesSansResultat
        .map((athlete) {
          return Resultat(
            id: '',
            mancheId: manche.id,
            athlete: athlete,
            position: null,
            points: 0,
            heureArrivee: null,
            tempsTotalMillisecondes: null,
            ecartPremierMillisecondes: null,
            statut: StatutResultat.horsDelai,
            commentaire: 'Délai dépassé à la fin de la manche.',
            datePublication: null,
            dateCreation: dateCreation,
            dateModification: dateCreation,
          );
        })
        .toList(growable: false);

    return _resultatRepository.enregistrerPlusieurs(resultatsHorsDelai);
  }

  void _verifierManche(Manche manche) {
    if (manche.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    if (!manche.estEnCours) {
      throw StateError(
        'Les athlètes ne peuvent être marqués '
        'hors délai que pendant une manche en cours.',
      );
    }

    if (manche.heurePremiereArrivee == null) {
      throw StateError(
        'La première arrivée n’a pas encore '
        'été enregistrée.',
      );
    }

    if (manche.heureFinDelai == null) {
      throw StateError(
        'La manche ne possède pas d’heure '
        'de fin de délai.',
      );
    }
  }
}
