import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/ports/suppression_compte_repository.dart';

class SuppressionCompteRepositorySupabase
    implements SuppressionCompteRepository {
  SuppressionCompteRepositorySupabase(this._client, this._stockage);
  final SupabaseClient _client;
  final LocalStorage _stockage;

  @override
  Future<void> supprimer(String motDePasse) async {
    if (_client.auth.currentSession == null) {
      throw StateError('Reconnecte-toi avant de supprimer ton compte.');
    }
    try {
      final reponse = await _client.functions.invoke(
        'supprimer-compte',
        body: {'motDePasse': motDePasse, 'confirmation': true},
      );
      if (reponse.status != 200 ||
          reponse.data is! Map ||
          reponse.data['supprime'] != true) {
        throw StateError(
          'La suppression n’a pas été confirmée. Réessaie ou contacte le support.',
        );
      }
    } on FunctionException catch (e) {
      final code = e.details is Map ? e.details['code'] : null;
      throw StateError(switch (code) {
        'mot_de_passe_incorrect' =>
          'Mot de passe incorrect. Vérifie-le et réessaie.',
        'session_invalide' => 'Ta session a expiré. Reconnecte-toi.',
        'mfa_requise' => 'Ce compte utilise la double authentification. Contacte le support pour vérifier ton identité.',
        'trop_de_demandes' =>
          'Trop de tentatives. Patiente avant de réessayer.',
        'suppression_indisponible' => 'La suppression est momentanément indisponible. Contacte le support ou réessaie plus tard.',
        _ => 'Impossible de supprimer ton compte. Réessaie ou contacte le support.',
      });
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError(
        'Connexion interrompue : la suppression n’est pas confirmée. Reconnecte-toi pour vérifier ou contacte le support.',
      );
    }
  }

  @override
  Future<void> effacerSessionLocale() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Le SDK retire d'abord la session en mémoire. Après suppression Auth,
      // la révocation réseau peut échouer car le compte n'existe plus.
      if (_client.auth.currentSession != null) {
        throw StateError(
          'Compte supprimé. Réessaie de fermer la session locale.',
        );
      }
    }
    await _stockage.removePersistedSession();
  }
}
