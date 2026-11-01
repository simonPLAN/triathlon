import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/athlete.dart';
import '../../../domain/ports/athlete_repository.dart';

class AthleteRepositorySupabase implements AthleteRepository {
  AthleteRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Athlete>> obtenirTous() async {
    try {
      final donnees = await _client
          .from('profils')
          .select('id, prenom, nom')
          .eq('role', 'athlete')
          .order('nom')
          .order('prenom');

      return donnees.map<Athlete>((ligne) {
        return Athlete(
          id: ligne['id'] as String,
          prenom: ligne['prenom'] as String,
          nom: ligne['nom'] as String,
        );
      }).toList();
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de charger les athlètes : '
        '${exception.message}',
      );
    } catch (exception) {
      throw Exception(
        'Erreur inattendue pendant le chargement '
        'des athlètes : $exception',
      );
    }
  }

  @override
  Future<void> ajouter(Athlete athlete) async {
    throw UnsupportedError(
      'Un athlète doit d’abord créer un compte utilisateur.',
    );
  }
}
