import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/manche.dart';
import '../../../domain/ports/configuration_manche_repository.dart';
import '../../../domain/ports/cycle_manche_repository.dart';
import '../../../domain/entities/statut_resultat.dart';
import 'manche_repository_supabase.dart';

class ConfigurationMancheRepositorySupabase
    implements ConfigurationMancheRepository, CycleMancheRepository {
  ConfigurationMancheRepositorySupabase(this._client);
  final SupabaseClient _client;

  @override
  Future<Manche> validerResultats(String mancheId, int revision) async {
    await _client.rpc(
      'valider_resultats_manche',
      params: {'p_manche_id': mancheId, 'p_revision': revision},
    );
    final manche = await MancheRepositorySupabase(_client)
        .obtenirParId(mancheId);
    if (manche == null) throw StateError('La validation doit être actualisée.');
    return manche;
  }

  @override
  Future<Manche> cloturerDelai(String mancheId) async {
    final id = await _client.rpc(
      'cloturer_delai_manche',
      params: {'p_manche_id': mancheId},
    ) as String;
    final manche = await MancheRepositorySupabase(_client).obtenirParId(id);
    if (manche == null) throw StateError('La clôture doit être actualisée.');
    return manche;
  }

  @override
  Future<void> declarerStatut({
    required String mancheId,
    required String athleteId,
    required StatutResultat statut,
    required String motif,
  }) async {
    await _client.rpc(
      'declarer_statut_participant',
      params: {
        'p_manche_id': mancheId,
        'p_athlete_id': athleteId,
        'p_statut': statut == StatutResultat.abandon
            ? 'abandon'
            : 'disqualifie',
        'p_motif': motif,
      },
    );
  }

  @override
  Future<Manche> configurer({
    required String mancheId,
    required List<String> athleteIds,
    required int dureeLimiteSecondes,
  }) async {
    await _client.rpc(
      'configurer_participants_manche',
      params: {
        'p_manche_id': mancheId,
        'p_athlete_ids': athleteIds,
        'p_duree_limite_secondes': dureeLimiteSecondes,
      },
    );
    final manche = await MancheRepositorySupabase(_client)
        .obtenirParId(mancheId);
    if (manche == null) {
      throw StateError('La manche configurée est introuvable.');
    }
    return manche;
  }
}
