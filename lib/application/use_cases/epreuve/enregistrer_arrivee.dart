import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../../domain/ports/resultat_repository.dart';
import '../../../domain/services/calcul_points.dart';

class EnregistrerArrivee {
  EnregistrerArrivee(this._resultatRepository, this._calculPoints);

  final ResultatRepository _resultatRepository;
  final CalculPoints _calculPoints;

  Future<Resultat> executer({
    required Manche manche,
    required Athlete athlete,
    DateTime? heureArrivee,
  }) async {
    _verifierManche(manche);
    _verifierAthlete(athlete);

    final arrivee = heureArrivee ?? DateTime.now();

    _verifierHeureArrivee(manche: manche, heureArrivee: arrivee);

    final resultatExistant = await _resultatRepository
        .obtenirParAthleteEtManche(mancheId: manche.id, athleteId: athlete.id);

    if (resultatExistant != null) {
      throw StateError(
        'Un résultat existe déjà pour cet athlète '
        'dans cette manche.',
      );
    }

    final resultatsExistants = await _resultatRepository.obtenirParManche(
      manche.id,
    );

    final resultatsArrives = resultatsExistants
        .where((resultat) => resultat.estArrive)
        .toList(growable: false);

    final position = resultatsArrives.length + 1;

    final tempsTotalMillisecondes = arrivee
        .difference(manche.heureDepart!)
        .inMilliseconds;

    final heurePremiereArrivee = _obtenirHeurePremiereArrivee(
      manche: manche,
      resultatsArrives: resultatsArrives,
      heureArriveeActuelle: arrivee,
    );

    final ecartPremierMillisecondes = arrivee
        .difference(heurePremiereArrivee)
        .inMilliseconds;

    final maintenant = DateTime.now();

    final resultat = Resultat(
      id: '',
      mancheId: manche.id,
      athlete: athlete,
      position: position,
      points: _calculPoints.pourPosition(position),
      heureArrivee: arrivee,
      tempsTotalMillisecondes: tempsTotalMillisecondes,
      ecartPremierMillisecondes: ecartPremierMillisecondes,
      statut: StatutResultat.arrive,
      dateCreation: maintenant,
      dateModification: maintenant,
    );

    return _resultatRepository.enregistrer(resultat);
  }

  void _verifierManche(Manche manche) {
    if (manche.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    if (!manche.estEnCours) {
      throw StateError(
        'Une arrivée ne peut être enregistrée '
        'que pendant une manche en cours.',
      );
    }

    if (manche.heureDepart == null) {
      throw StateError('La manche ne possède pas d’heure de départ.');
    }
  }

  void _verifierAthlete(Athlete athlete) {
    if (athlete.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de l’athlète est obligatoire.');
    }
  }

  void _verifierHeureArrivee({
    required Manche manche,
    required DateTime heureArrivee,
  }) {
    if (heureArrivee.isBefore(manche.heureDepart!)) {
      throw ArgumentError(
        'L’heure d’arrivée ne peut pas précéder '
        'l’heure de départ.',
      );
    }
  }

  DateTime _obtenirHeurePremiereArrivee({
    required Manche manche,
    required List<Resultat> resultatsArrives,
    required DateTime heureArriveeActuelle,
  }) {
    final heureDansManche = manche.heurePremiereArrivee;

    if (heureDansManche != null) {
      return heureDansManche;
    }

    final heuresExistantes = resultatsArrives
        .map((resultat) => resultat.heureArrivee)
        .whereType<DateTime>()
        .toList();

    if (heuresExistantes.isEmpty) {
      return heureArriveeActuelle;
    }

    heuresExistantes.sort();

    return heuresExistantes.first;
  }
}
