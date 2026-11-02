import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/edition_resultat.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../../domain/ports/edition_resultats_repository.dart';

class CorrigerResultat {
  CorrigerResultat(this._repository);
  final EditionResultatsRepository _repository;

  Future<EditionResultats> executer({
    required Manche manche,
    required Athlete athlete,
    Resultat? resultat,
    required StatutResultat statut,
    required ModeReclassement mode,
    int? position,
    int? tempsMillisecondes,
    String? commentaire,
    bool accepterDepublication = false,
  }) {
    if (!manche.estTerminee || manche.heureDepart == null) {
      throw StateError(
        'Termine la manche avant de saisir ou corriger un résultat.',
      );
    }
    if (manche.id.isEmpty ||
        athlete.id.isEmpty ||
        (resultat != null &&
            (resultat.mancheId != manche.id ||
                resultat.athlete.id != athlete.id))) {
      throw ArgumentError(
        'Le résultat et l’athlète doivent appartenir à cette manche.',
      );
    }
    if (manche.resultatsPublies && !accepterDepublication) {
      throw StateError(
        'Confirme le retrait de publication de toute la manche.',
      );
    }
    if ((commentaire?.length ?? 0) > 1000) {
      throw ArgumentError('Commentaire : 1 000 caractères maximum.');
    }
    if (statut == StatutResultat.arrive) {
      if (tempsMillisecondes == null ||
          tempsMillisecondes < 0 ||
          tempsMillisecondes > 604800000) {
        throw ArgumentError(
          'Saisis un temps compris entre zéro et sept jours.',
        );
      }
      if (mode != ModeReclassement.temps &&
          (position == null || position < 1)) {
        throw ArgumentError('Saisis une position supérieure à zéro.');
      }
      if (mode == ModeReclassement.echanger && resultat?.estArrive != true) {
        throw ArgumentError('L’échange nécessite un athlète déjà classé.');
      }
      if (manche.heureFinDelai != null &&
          !manche.heureDepart!
              .add(Duration(milliseconds: tempsMillisecondes))
              .isBefore(manche.heureFinDelai!)) {
        throw ArgumentError(
          'Ce temps atteint le délai limite. Utilise le statut Hors délai.',
        );
      }
    } else if (position != null || tempsMillisecondes != null) {
      throw ArgumentError(
        'Un statut sans arrivée ne possède ni place ni temps.',
      );
    }
    return _repository.editer(
      ModificationResultat(
        mancheId: manche.id,
        athleteId: athlete.id,
        resultatId: resultat?.id,
        revision: manche.revisionResultats,
        statut: statut,
        mode: mode,
        position: position,
        tempsMillisecondes: tempsMillisecondes,
        commentaire: commentaire?.trim(),
        accepterDepublication: accepterDepublication,
      ),
    );
  }
}
