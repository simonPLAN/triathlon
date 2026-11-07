import '../../../domain/entities/edition_resultat.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import 'corriger_resultat.dart';

/// Un bonus soustrait un temps ; une pénalité ajoute un temps.
/// L'ajustement est conservé dans le commentaire et le classement est recalculé.
class AjusterTempsResultat {
  AjusterTempsResultat(this._corriger);
  final CorrigerResultat _corriger;

  Future<EditionResultats> executer({
    required Manche manche,
    required Resultat resultat,
    required int deltaMillisecondes,
    required String motif,
    bool accepterDepublication = false,
  }) {
    final temps = resultat.tempsTotalMillisecondes;
    if (!resultat.estArrive || temps == null) {
      throw StateError('Seul un résultat arrivé possède un temps ajustable.');
    }
    if (deltaMillisecondes == 0 || deltaMillisecondes.abs() > 86400000) {
      throw ArgumentError(
        'L’ajustement doit être non nul et ne pas dépasser 24 heures.',
      );
    }
    if (motif.trim().isEmpty || motif.trim().length > 300) {
      throw ArgumentError('Indique un motif de 1 à 300 caractères.');
    }
    final secondes = (deltaMillisecondes.abs() / 1000).toStringAsFixed(3);
    final libelle = deltaMillisecondes > 0
        ? 'Pénalité +${secondes}s'
        : 'Bonus -${secondes}s';
    final commentaire = [
      if ((resultat.commentaire ?? '').isNotEmpty) resultat.commentaire!,
      '$libelle : ${motif.trim()}',
    ].join('\n');
    return _corriger.executer(
      manche: manche,
      athlete: resultat.athlete,
      resultat: resultat,
      statut: StatutResultat.arrive,
      mode: ModeReclassement.temps,
      tempsMillisecondes: temps + deltaMillisecondes,
      commentaire: commentaire,
      accepterDepublication: accepterDepublication,
    );
  }
}
