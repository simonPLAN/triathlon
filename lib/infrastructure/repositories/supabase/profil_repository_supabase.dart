import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/profil_utilisateur.dart';
import '../../../domain/entities/role_utilisateur.dart';
import '../../../domain/ports/profil_repository.dart';

class ProfilRepositorySupabase implements ProfilRepository {
  ProfilRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ProfilUtilisateur> obtenirProfilConnecte() async {
    final utilisateur = _client.auth.currentUser;

    if (utilisateur == null) {
      throw Exception('Aucun utilisateur connecté.');
    }

    try {
      final donnees = await _client
          .from('profils')
          .select('id, pseudo, role')
          .eq('id', utilisateur.id)
          .single();

      return ProfilUtilisateur(
        id: donnees['id'] as String,
        pseudo: donnees['pseudo'] as String,
        role: _convertirRole(donnees['role'] as String),
      );
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de récupérer le profil : '
        '${exception.message}',
      );
    } catch (exception) {
      if (exception is Exception) {
        rethrow;
      }

      throw Exception(
        'Une erreur inattendue est survenue '
        'pendant le chargement du profil.',
      );
    }
  }

  RoleUtilisateur _convertirRole(String role) {
    switch (role) {
      case 'coach':
        return RoleUtilisateur.coach;

      case 'athlete':
        return RoleUtilisateur.athlete;

      default:
        throw Exception('Rôle utilisateur inconnu : $role');
    }
  }
}
