import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/groupe_athletes.dart';
import '../../../domain/ports/groupe_athletes_repository.dart';

class GroupeAthletesRepositorySupabase implements GroupeAthletesRepository {
  GroupeAthletesRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GroupeAthletes>> lister() async {
    final lignes = await _client
        .from('groupes_athletes')
        .select('id,nom,groupe_athletes_membres(athlete_id)')
        .order('nom');
    return (lignes as List)
        .map((element) {
          final ligne = Map<String, dynamic>.from(element as Map);
          final membres =
              (ligne['groupe_athletes_membres'] as List? ?? const []);
          return GroupeAthletes(
            id: ligne['id'] as String,
            nom: ligne['nom'] as String,
            athleteIds: membres.map(
              (membre) => (membre as Map)['athlete_id'] as String,
            ),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<GroupeAthletes> enregistrer({
    String? id,
    required String nom,
    required List<String> athleteIds,
  }) async {
    try {
      final resultat = await _client.rpc(
        'enregistrer_groupe_athletes',
        params: {'p_groupe_id': id, 'p_nom': nom, 'p_athlete_ids': athleteIds},
      );
      final ligne = Map<String, dynamic>.from(resultat as Map);
      return GroupeAthletes(
        id: ligne['id'] as String,
        nom: ligne['nom'] as String,
        athleteIds: (ligne['athlete_ids'] as List).cast<String>(),
      );
    } on PostgrestException catch (exception) {
      if (exception.code == '23505') {
        throw StateError('Un groupe porte déjà ce nom.');
      }
      throw StateError(exception.message);
    }
  }

  @override
  Future<void> supprimer(String id) async {
    try {
      await _client.rpc(
        'supprimer_groupe_athletes',
        params: {'p_groupe_id': id},
      );
    } on PostgrestException catch (exception) {
      throw StateError(exception.message);
    }
  }
}
