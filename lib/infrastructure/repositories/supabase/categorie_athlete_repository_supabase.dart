import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/categorie_athlete.dart';
import '../../../domain/ports/categorie_athlete_repository.dart';

class CategorieAthleteRepositorySupabase implements CategorieAthleteRepository {
  CategorieAthleteRepositorySupabase(this.client);
  final SupabaseClient client;
  Future<dynamic> _appeler(String fonction, Map<String, dynamic> params) async {
    try {
      return await client
          .rpc(fonction, params: params)
          .timeout(const Duration(seconds: 20));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' || e.code == '42P01') {
        throw StateError(
          'Les catégories doivent être activées sur le serveur.',
        );
      }
      throw StateError(
        'Impossible d’accéder à cette catégorie. Vérifie tes droits et réessaie.',
      );
    }
  }

  @override
  Future<CategorieAthlete> obtenir(String athleteId) async {
    final data = Map<String, dynamic>.from(
      await _appeler('consulter_categorie_athlete', {'p_athlete_id': athleteId})
          as Map,
    );
    return CategorieAthlete(
      categorie: data['categorie'] as String?,
      modifiable: data['modifiable'] == true,
    );
  }

  @override
  Future<void> enregistrer(String athleteId, String? categorie) async {
    await _appeler('configurer_categorie_athlete', {
      'p_athlete_id': athleteId,
      'p_categorie': categorie,
    });
  }
}
