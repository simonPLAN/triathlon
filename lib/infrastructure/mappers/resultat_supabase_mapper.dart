import '../../domain/entities/athlete.dart';
import '../../domain/entities/resultat.dart';
import '../../domain/entities/statut_resultat.dart';

class ResultatSupabaseMapper {
  static Resultat lire(Map<String, dynamic> donnees) {
    final donneesProfil = donnees['profils'] as Map<String, dynamic>?;

    if (donneesProfil == null) {
      throw const FormatException('Le profil de l’athlète est introuvable.');
    }

    final pseudo = donneesProfil['pseudo'] as String?;
    final athlete = Athlete(
      id: donneesProfil['id'] as String,
      pseudo: pseudo,
      prenom: pseudo == null ? donneesProfil['prenom'] as String? ?? '' : '',
      nom: pseudo == null ? donneesProfil['nom'] as String? ?? '' : '',
    );

    return Resultat(
      id: donnees['id'] as String,
      mancheId: donnees['manche_id'] as String,
      athlete: athlete,
      position: donnees['position'] as int?,
      points: donnees['points'] as int,
      heureArrivee: _convertirDateFacultative(donnees['heure_arrivee']),
      tempsTotalMillisecondes: donnees['temps_total_millisecondes'] as int?,
      ecartPremierMillisecondes: donnees['ecart_premier_millisecondes'] as int?,
      statut: _convertirStatutDepuisSupabase(donnees['statut'] as String),
      commentaire: donnees['commentaire'] as String?,
      datePublication: _convertirDateFacultative(donnees['date_publication']),
      dateCreation: DateTime.parse(donnees['date_creation'] as String)
          .toLocal(),
      dateModification: DateTime.parse(donnees['date_modification'] as String)
          .toLocal(),
    );
  }

  static DateTime? _convertirDateFacultative(dynamic valeur) {
    if (valeur == null) {
      return null;
    }

    return DateTime.parse(valeur as String).toLocal();
  }

  static StatutResultat _convertirStatutDepuisSupabase(String statut) {
    switch (statut) {
      case 'arrive':
        return StatutResultat.arrive;

      case 'hors_delai':
        return StatutResultat.horsDelai;

      case 'abandon':
        return StatutResultat.abandon;

      case 'disqualifie':
        return StatutResultat.disqualifie;

      default:
        throw FormatException('Statut de résultat inconnu : $statut');
    }
  }
}
