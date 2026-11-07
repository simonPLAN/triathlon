import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/invite_repository.dart';

class InviteRepositorySupabase implements InviteRepository {
  InviteRepositorySupabase(this._client);
  final SupabaseClient _client;

  @override
  Future<Inscription> inscrire({
    required String competitionId,
    required String pseudo,
    int? numeroDossard,
  }) async {
    try {
      final data = await _client.rpc(
        'inscrire_invite',
        params: {
          'p_competition_id': competitionId,
          'p_pseudo': pseudo,
          'p_numero_dossard': numeroDossard,
        },
      );
      final row = Map<String, dynamic>.from(data as Map);
      return Inscription(
        id: row['id'] as String,
        competitionId: competitionId,
        athlete: Athlete(id: row['athlete_id'] as String, pseudo: pseudo),
        numeroDossard: row['numero_dossard'] as int?,
        dateInscription: DateTime.parse(row['date_inscription'] as String),
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw StateError(
          e.message.toLowerCase().contains('pseudo')
              ? 'Ce pseudo est déjà utilisé.'
              : 'Ce dossard est déjà utilisé dans cette compétition.',
        );
      }
      if (e.code == 'PGRST202') {
        throw StateError(
          'La migration des pseudos doit être appliquée sur le serveur.',
        );
      }
      throw StateError(e.message);
    }
  }
}
