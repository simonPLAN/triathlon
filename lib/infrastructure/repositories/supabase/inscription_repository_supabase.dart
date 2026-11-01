import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/ports/inscription_repository.dart';

class InscriptionRepositorySupabase implements InscriptionRepository {
  InscriptionRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const String _nomTable = 'inscriptions';

  static const String _selectionComplete = '''
    id,
    competition_id,
    athlete_id,
    numero_dossard,
    date_inscription,
    profils!inscriptions_athlete_id_fkey (
      id,
      prenom,
      nom
    )
  ''';

  @override
  Future<List<Inscription>> obtenirParCompetition(String competitionId) async {
    final idNettoye = competitionId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    _verifierUtilisateurConnecte();

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_selectionComplete)
          .eq('competition_id', idNettoye)
          .order('numero_dossard', ascending: true, nullsFirst: false);

      return donnees
          .map<Inscription>(_convertirDepuisSupabase)
          .toList(growable: false);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de charger les inscriptions : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<Inscription> inscrire({
    required String competitionId,
    required String athleteId,
    int? numeroDossard,
  }) async {
    final competitionIdNettoye = competitionId.trim();

    final athleteIdNettoye = athleteId.trim();

    if (competitionIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (athleteIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’athlète est obligatoire.');
    }

    if (numeroDossard != null && numeroDossard <= 0) {
      throw ArgumentError('Le numéro de dossard doit être supérieur à zéro.');
    }

    _verifierUtilisateurConnecte();

    try {
      final donneesInscription = await _client
          .from(_nomTable)
          .insert({
            'competition_id': competitionIdNettoye,
            'athlete_id': athleteIdNettoye,
            'numero_dossard': numeroDossard,
          })
          .select('id')
          .single();

      return await _obtenirParId(donneesInscription['id'] as String);
    } on PostgrestException catch (exception) {
      throw Exception(_traduireErreurSupabase(exception));
    }
  }

  @override
  Future<Inscription> modifierNumeroDossard({
    required String inscriptionId,
    int? numeroDossard,
  }) async {
    final idNettoye = inscriptionId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’inscription est obligatoire.');
    }

    if (numeroDossard != null && numeroDossard <= 0) {
      throw ArgumentError('Le numéro de dossard doit être supérieur à zéro.');
    }

    _verifierUtilisateurConnecte();

    try {
      final donneesInscription = await _client
          .from(_nomTable)
          .update({'numero_dossard': numeroDossard})
          .eq('id', idNettoye)
          .select('id')
          .single();

      return await _obtenirParId(donneesInscription['id'] as String);
    } on PostgrestException catch (exception) {
      throw Exception(_traduireErreurSupabase(exception));
    }
  }

  @override
  Future<void> desinscrire(String inscriptionId) async {
    final idNettoye = inscriptionId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’inscription est obligatoire.');
    }

    _verifierUtilisateurConnecte();

    try {
      await _client.from(_nomTable).delete().eq('id', idNettoye);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de désinscrire l’athlète : '
        '${exception.message}',
      );
    }
  }

  Future<Inscription> _obtenirParId(String inscriptionId) async {
    final donnees = await _client
        .from(_nomTable)
        .select(_selectionComplete)
        .eq('id', inscriptionId)
        .single();

    return _convertirDepuisSupabase(donnees);
  }

  Inscription _convertirDepuisSupabase(Map<String, dynamic> donnees) {
    final donneesProfil = donnees['profils'] as Map<String, dynamic>?;

    if (donneesProfil == null) {
      throw const FormatException('Le profil de l’athlète est introuvable.');
    }

    final athlete = Athlete(
      id: donneesProfil['id'] as String,
      prenom: donneesProfil['prenom'] as String,
      nom: donneesProfil['nom'] as String,
    );

    return Inscription(
      id: donnees['id'] as String,
      competitionId: donnees['competition_id'] as String,
      athlete: athlete,
      numeroDossard: donnees['numero_dossard'] as int?,
      dateInscription: DateTime.parse(donnees['date_inscription'] as String),
    );
  }

  User _verifierUtilisateurConnecte() {
    final utilisateur = _client.auth.currentUser;

    if (utilisateur == null) {
      throw StateError('Aucun utilisateur connecté.');
    }

    return utilisateur;
  }

  String _traduireErreurSupabase(PostgrestException exception) {
    final details = '${exception.message} ${exception.details}'.toLowerCase();

    if (exception.code == '23505') {
      if (details.contains('competition_id_numero_dossard') ||
          details.contains('numero_dossard')) {
        return 'Ce numéro de dossard est déjà utilisé '
            'dans cette compétition.';
      }

      if (details.contains('competition_id_athlete_id') ||
          details.contains('athlete_id')) {
        return 'Tu es déjà inscrit à cette compétition.';
      }

      return 'Cette inscription existe déjà.';
    }

    if (exception.code == '23503') {
      return 'La compétition ou le profil athlète '
          'est introuvable.';
    }

    if (exception.code == '23514') {
      return 'Le numéro de dossard doit être '
          'supérieur à zéro.';
    }

    if (exception.code == '42501') {
      return 'Tu ne peux pas t’inscrire à cette compétition. '
          'Vérifie que les inscriptions sont ouvertes.';
    }

    return 'Opération impossible sur l’inscription : '
        '${exception.message}';
  }

  @override
  Future<Inscription> inscrireUtilisateurConnecte({
    required String competitionId,
  }) async {
    final competitionIdNettoye = competitionId.trim();

    if (competitionIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    final utilisateur = _verifierUtilisateurConnecte();

    try {
      final donneesInscription = await _client
          .from(_nomTable)
          .insert({
            'competition_id': competitionIdNettoye,
            'athlete_id': utilisateur.id,
            'numero_dossard': null,
          })
          .select('id')
          .single();

      return await _obtenirParId(donneesInscription['id'] as String);
    } on PostgrestException catch (exception) {
      throw Exception(_traduireErreurSupabase(exception));
    }
  }

  @override
  Future<Inscription?> obtenirInscriptionUtilisateurConnecte({
    required String competitionId,
  }) async {
    final competitionIdNettoye = competitionId.trim();

    if (competitionIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    final utilisateur = _verifierUtilisateurConnecte();

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_selectionComplete)
          .eq('competition_id', competitionIdNettoye)
          .eq('athlete_id', utilisateur.id)
          .maybeSingle();

      if (donnees == null) {
        return null;
      }

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de vérifier l’inscription : '
        '${exception.message}',
      );
    }
  }
}
