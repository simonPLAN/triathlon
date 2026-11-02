import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/edition_resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../../domain/ports/edition_resultats_repository.dart';
import '../../mappers/resultat_supabase_mapper.dart';

class EditionResultatsRepositorySupabase implements EditionResultatsRepository {
  EditionResultatsRepositorySupabase(this._client);
  final SupabaseClient _client;

  @override
  Future<EditionResultats> editer(ModificationResultat modification) async {
    try {
      final data = await _client.rpc(
        'editer_resultat_manche',
        params: {
          'p_manche_id': modification.mancheId,
          'p_athlete_id': modification.athleteId,
          'p_resultat_id': modification.resultatId,
          'p_revision': modification.revision,
          'p_statut': switch (modification.statut) {
            StatutResultat.arrive => 'arrive',
            StatutResultat.horsDelai => 'hors_delai',
            StatutResultat.abandon => 'abandon',
            StatutResultat.disqualifie => 'disqualifie',
          },
          'p_mode': modification.mode.name,
          'p_position': modification.position,
          'p_temps_ms': modification.tempsMillisecondes,
          'p_commentaire': modification.commentaire,
          'p_accepter_depublication': modification.accepterDepublication,
        },
      ) as Map;
      return EditionResultats(
        resultats: List.unmodifiable(
          (data['resultats'] as List).map(
            (r) => ResultatSupabaseMapper.lire(
              Map<String, dynamic>.from(r as Map),
            ),
          ),
        ),
        revision: (data['revision'] as num).toInt(),
        depublies: data['depublies'] == true,
      );
    } on PostgrestException catch (e) {
      if (e.code == '40001' || e.code == '40P01') {
        throw StateError(
          'Le classement a changé. Actualise la manche avant de réessayer.',
        );
      }
      if (e.code == 'P0001' || e.code == '42501' || e.code == '22023') {
        throw StateError(e.message);
      }
      if (e.code == '23505') {
        throw StateError(
          'Une place est déjà occupée. Actualise le classement.',
        );
      }
      if (e.code == 'PGRST202') {
        throw StateError(
          'La migration de correction des résultats doit être installée sur Supabase.',
        );
      }
      throw StateError(
        'La correction n’a pas pu être confirmée. Actualise les résultats puis réessaie.',
      );
    } catch (_) {
      throw StateError(
        'Connexion interrompue : la correction n’est pas confirmée. Actualise les résultats avant de réessayer.',
      );
    }
  }
}
