import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/entities/resultat_publie.dart';
import '../../../domain/ports/suivi_athlete_repository.dart';

class SuiviAthleteRepositorySupabase implements SuiviAthleteRepository {
  SuiviAthleteRepositorySupabase(this._client);
  final SupabaseClient _client;

  Future<List<dynamic>> _lire(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Connecte-toi pour consulter tes compétitions.');
    }
    try {
      return await _client.rpc(fonction, params: params) as List<dynamic>;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        throw StateError(
          'Le suivi des compétitions doit être activé sur le serveur.',
        );
      }
      throw StateError(e.message);
    }
  }

  @override
  Future<List<Competition>> obtenirCompetitionsInscrites() async {
    final rows = await _lire('mes_competitions_inscrites');
    return Future.wait(
      rows.map((row) async {
        final m = Map<String, dynamic>.from(row as Map);
        final imagePath = m['image_path'] as String?;
        Uri? imageUrl;
        if (imagePath != null && imagePath.isNotEmpty) {
          try {
            imageUrl = Uri.parse(
              await _client.storage
                  .from('images-competitions')
                  .createSignedUrl(imagePath, 3600),
            );
          } on StorageException {
            imageUrl = null;
          }
        }
        return Competition(
          imageUrl: imageUrl,
          id: m['id'] as String,
          nom: m['nom'] as String,
          description: m['description'] as String?,
          lieu: m['lieu'] as String?,
          dateCompetition: DateTime.parse(m['date_competition'] as String),
          coachId: m['coach_id'] as String,
          statut: switch (m['statut']) {
            'brouillon' => StatutCompetition.brouillon,
            'ouverte' => StatutCompetition.ouverte,
            'en_cours' => StatutCompetition.enCours,
            'terminee' => StatutCompetition.terminee,
            'annulee' => StatutCompetition.annulee,
            _ => throw const FormatException('Statut de compétition inconnu.'),
          },
          dateCreation: DateTime.parse(m['date_creation'] as String),
          dateModification: DateTime.parse(m['date_modification'] as String),
          demarrageAutomatiqueMancheSuivante:
              m['demarrage_automatique_manche_suivante'] as bool? ?? false,
        );
      }),
    );
  }

  @override
  Future<List<ResultatPublie>> obtenirResultatsPublies(
    String competitionId,
  ) async {
    final rows = await _lire('resultats_publies_athlete', {
      'p_competition_id': competitionId,
    });
    return rows.map((row) {
      final m = Map<String, dynamic>.from(row as Map);
      return ResultatPublie(
        athleteId: m['athlete_id'] as String,
        nomAthlete: m['nom_athlete'] as String,
        epreuveId: m['epreuve_id'] as String,
        nomEpreuve: m['nom_epreuve'] as String,
        mancheId: m['manche_id'] as String,
        numeroManche: m['numero_manche'] as int,
        position: m['position'] as int?,
        points: m['points'] as int,
        statut: m['statut'] as String,
        tempsMillisecondes: m['temps_total_millisecondes'] as int?,
      );
    }).toList();
  }
}
