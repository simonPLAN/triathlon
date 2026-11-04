import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/ports/confirmation_email_repository.dart';

class ConfirmationEmailRepositorySupabase implements ConfirmationEmailRepository {
  ConfirmationEmailRepositorySupabase(this._client, {required this.redirection});
  final SupabaseClient _client;
  final Uri redirection;
  @override
  bool get possedeSession => _client.auth.currentSession != null;

  @override
  Future<void> renvoyer(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: redirection.toString(),
      );
    } on AuthException catch (_) {
      throw StateError('L’e-mail n’a pas pu être renvoyé. Patiente quelques instants puis réessaie.');
    }
  }

  @override
  Future<void> confirmer(String code) async {
    try {
      final reponse = await _client.auth.exchangeCodeForSession(code);
      if (reponse.session.user.emailConfirmedAt == null) {
        await _client.auth.signOut(scope: SignOutScope.local);
        throw StateError('Cette adresse n’est pas encore confirmée.');
      }
      // La confirmation est terminée ; l’utilisateur choisit ensuite sa connexion.
      await _client.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (_) {
      throw StateError('Le lien a expiré, a déjà été utilisé ou a été demandé sur une autre installation. Demande un nouveau lien.');
    }
  }
}
