import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../../domain/ports/resultat_repository.dart';
import '../../../domain/services/calcul_points.dart';

class CorrigerResultat {
  CorrigerResultat(this._repository, this._calculPoints);

  final ResultatRepository _repository;
  final CalculPoints _calculPoints;

  Future<Resultat> executer({
    required Resultat resultat,
    required StatutResultat statut,
    int? position,
    String? commentaire,
  }) {
    final estArrive = statut == StatutResultat.arrive;
    if (estArrive && (position == null || position <= 0)) {
      throw ArgumentError('Une arrivée doit avoir une position valide.');
    }
    if (!estArrive && position != null) {
      throw ArgumentError('Ce statut ne peut pas avoir de position.');
    }

    final corrige = resultat.copierAvec(
      statut: statut,
      position: estArrive ? position : null,
      supprimerPosition: !estArrive,
      supprimerHeureArrivee: !estArrive,
      supprimerTempsTotal: !estArrive,
      supprimerEcartPremier: !estArrive,
      points: estArrive ? _calculPoints.pourPosition(position!) : 0,
      commentaire: commentaire?.trim().isEmpty == true
          ? null
          : commentaire?.trim(),
      supprimerCommentaire: commentaire?.trim().isEmpty == true,
      dateModification: DateTime.now(),
    );
    return _repository.modifier(corrige);
  }
}
