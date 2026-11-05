import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/ports/recuperation_compte_repository.dart';

class RecuperationCompteRepositorySupabase
    implements RecuperationCompteRepository {
  RecuperationCompteRepositorySupabase(this._client);
  final SupabaseClient _client;
  String? _utilisateurRecuperation;

  @override
  Future<void> envoyerLien(String email, Uri redirection) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirection.toString(),
      );
    } on AuthException catch (e) {
      throw StateError(_message(e));
    } catch (_) {
      throw StateError('Connexion impossible. Vérifie Internet puis réessaie.');
    }
  }

  @override
  Future<void> verifierLien(Uri lien) async {
    // Conserver la session de récupération précédente pour pouvoir la fermer
    // même si un second lien reçu pendant le parcours est invalide.
    try {
      final fragment = Uri.splitQueryString(lien.fragment);
      final parametres = {...lien.queryParameters, ...fragment};
      if (parametres.containsKey('error') ||
          parametres.containsKey('error_code') ||
          parametres.containsKey('error_description')) {
        throw const AuthException(
          'Lien expiré ou invalide',
          code: 'otp_expired',
        );
      }
      // Le flux PKCE conserve le type d'opération dans le vérificateur local.
      // On exige un code : un fragment forgé type=recovery ne suffit pas.
      if ((lien.queryParameters['code'] ?? '').isEmpty) {
        throw const AuthException(
          'Code de récupération absent',
          code: 'otp_expired',
        );
      }
      final reponse = await _client.auth.getSessionFromUrl(lien);
      if (reponse.redirectType != 'passwordRecovery' &&
          reponse.redirectType != 'recovery') {
        await _client.auth.signOut(scope: SignOutScope.local);
        throw const AuthException(
          'Ce lien ne réinitialise pas le mot de passe',
          code: 'otp_expired',
        );
      }
      if (reponse.session.isExpired) {
        throw const AuthException('Session expirée', code: 'session_expired');
      }
      _utilisateurRecuperation = reponse.session.user.id;
    } on AuthException catch (e) {
      throw StateError(_message(e));
    } on FormatException {
      throw StateError('Ce lien est invalide. Demande un nouveau lien.');
    } catch (_) {
      throw StateError(
        'Impossible de vérifier ce lien. Vérifie Internet ou demande un nouveau lien.',
      );
    }
  }

  @override
  Future<void> changerMotDePasse(String motDePasse) async {
    final session = _client.auth.currentSession;
    if (_utilisateurRecuperation == null ||
        session == null ||
        session.user.id != _utilisateurRecuperation ||
        session.isExpired) {
      throw StateError(
        'La session de récupération a expiré. Demande un nouveau lien.',
      );
    }
    try {
      await _client.auth.updateUser(UserAttributes(password: motDePasse));
    } on AuthException catch (e) {
      throw StateError(_message(e));
    } catch (_) {
      throw StateError(
        'Le mot de passe n’a pas pu être enregistré. Vérifie Internet puis réessaie.',
      );
    }
  }

  @override
  Future<void> terminer() async {
    if (_utilisateurRecuperation != null &&
        _client.auth.currentUser?.id == _utilisateurRecuperation) {
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        throw StateError(
          'Impossible de fermer la session de récupération. Réessaie.',
        );
      }
    }
    _utilisateurRecuperation = null;
  }

  String _message(AuthException e) {
    final texte = e.message.toLowerCase();
    if (e.statusCode == '429' ||
        texte.contains('rate limit') ||
        texte.contains('too many') ||
        texte.contains('security purposes')) {
      return 'Trop de demandes. Patiente quelques instants avant de réessayer.';
    }
    if (e.code == 'same_password' || texte.contains('different from the old')) {
      return 'Choisis un mot de passe différent de l’ancien.';
    }
    if (e.code == 'weak_password' || texte.contains('password should')) {
      return 'Le mot de passe ne respecte pas les règles de sécurité. Choisis-en un plus robuste.';
    }
    return 'Ce lien est expiré, déjà utilisé ou ouvert sur un autre appareil. '
        'Demande un nouveau lien et ouvre-le dans l’application qui l’a demandé.';
  }
}
