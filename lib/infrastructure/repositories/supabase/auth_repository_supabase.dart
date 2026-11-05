import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/ports/auth_repository.dart';

class AuthRepositorySupabase implements AuthRepository {
  AuthRepositorySupabase(this._client, {this.redirectionConfirmation});

  final SupabaseClient _client;
  final Uri? redirectionConfirmation;

  @override
  bool get estConnecte {
    return _client.auth.currentSession != null;
  }

  @override
  Future<void> connecter({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final reponse = await _client.auth.signInWithPassword(
        email: email,
        password: motDePasse,
      );

      if (reponse.session == null) {
        throw Exception('La connexion n’a pas pu être établie.');
      }
    } on AuthException catch (exception) {
      throw Exception(_traduireErreur(exception.message));
    }
  }

  @override
  Future<void> inscrireAthlete({
    required String prenom,
    required String nom,
    required String email,
    required String motDePasse,
  }) async {
    try {
      final reponse = await _client.auth.signUp(
        email: email,
        password: motDePasse,
        data: {'prenom': prenom, 'nom': nom},
        emailRedirectTo: redirectionConfirmation?.toString(),
      );

      if (reponse.user == null) {
        throw Exception('Le compte utilisateur n’a pas pu être créé.');
      }
    } on AuthException catch (exception) {
      throw Exception(_traduireErreur(exception.message));
    }
  }

  @override
  Future<void> deconnecter() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (exception) {
      throw Exception(_traduireErreur(exception.message));
    }
  }

  String _traduireErreur(String message) {
    final erreur = message.toLowerCase();

    if (erreur.contains('invalid login credentials')) {
      return 'Adresse e-mail ou mot de passe incorrect.';
    }

    if (erreur.contains('email not confirmed')) {
      return 'Confirme ton adresse e-mail avant de te connecter.';
    }

    if (erreur.contains('user already registered')) {
      return 'Un compte existe déjà avec cette adresse e-mail.';
    }

    return message;
  }
}
