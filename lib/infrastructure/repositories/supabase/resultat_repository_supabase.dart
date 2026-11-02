import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mappers/resultat_supabase_mapper.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../../domain/ports/resultat_repository.dart';

class ResultatRepositorySupabase implements ResultatRepository {
  ResultatRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const String _nomTable = 'resultats';

  static const String _selectionComplete = '''
    id,
    manche_id,
    athlete_id,
    position,
    points,
    heure_arrivee,
    temps_total_millisecondes,
    ecart_premier_millisecondes,
    statut,
    commentaire,
    date_publication,
    date_creation,
    date_modification,
    profils!resultats_athlete_id_fkey (
      id,
      prenom,
      nom
    )
  ''';

  @override
  Future<List<Resultat>> obtenirParManche(String mancheId) async {
    final idNettoye = mancheId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_selectionComplete)
          .eq('manche_id', idNettoye)
          .order('position', ascending: true, nullsFirst: false);

      return donnees
          .map<Resultat>(ResultatSupabaseMapper.lire)
          .toList(growable: false);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de charger les résultats : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<Resultat?> obtenirParAthleteEtManche({
    required String mancheId,
    required String athleteId,
  }) async {
    final mancheIdNettoye = mancheId.trim();
    final athleteIdNettoye = athleteId.trim();

    if (mancheIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    if (athleteIdNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’athlète est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_selectionComplete)
          .eq('manche_id', mancheIdNettoye)
          .eq('athlete_id', athleteIdNettoye)
          .maybeSingle();

      if (donnees == null) {
        return null;
      }

      return ResultatSupabaseMapper.lire(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de vérifier le résultat : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<Resultat> enregistrer(Resultat resultat) async {
    try {
      final donnees = await _client
          .from(_nomTable)
          .insert(_convertirPourCreation(resultat))
          .select(_selectionComplete)
          .single();

      return ResultatSupabaseMapper.lire(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(_traduireErreurSupabase(exception));
    }
  }

  @override
  Future<Resultat> modifier(Resultat resultat) async {
    final idNettoye = resultat.id.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant du résultat est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .update(_convertirPourModification(resultat))
          .eq('id', idNettoye)
          .select(_selectionComplete)
          .single();

      return ResultatSupabaseMapper.lire(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(_traduireErreurSupabase(exception));
    }
  }

  @override
  Future<List<Resultat>> enregistrerPlusieurs(List<Resultat> resultats) async {
    if (resultats.isEmpty) {
      return const [];
    }

    final mancheId = resultats.first.mancheId;

    final memeManche = resultats.every(
      (resultat) => resultat.mancheId == mancheId,
    );

    if (!memeManche) {
      throw ArgumentError(
        'Tous les résultats doivent appartenir '
        'à la même manche.',
      );
    }

    try {
      final valeurs = resultats
          .map(_convertirPourCreation)
          .toList(growable: false);

      final donnees = await _client
          .from(_nomTable)
          .insert(valeurs)
          .select(_selectionComplete);

      final resultatsCrees = donnees
          .map<Resultat>(ResultatSupabaseMapper.lire)
          .toList(growable: false);

      resultatsCrees.sort(_comparerResultats);

      return List.unmodifiable(resultatsCrees);
    } on PostgrestException catch (exception) {
      throw Exception(_traduireErreurSupabase(exception));
    }
  }

  @override
  Future<void> supprimer(String resultatId) async {
    final idNettoye = resultatId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant du résultat est obligatoire.');
    }

    try {
      await _client.from(_nomTable).delete().eq('id', idNettoye);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de supprimer le résultat : '
        '${exception.message}',
      );
    }
  }

  Map<String, dynamic> _convertirPourCreation(Resultat resultat) {
    return {
      'manche_id': resultat.mancheId,
      'athlete_id': resultat.athlete.id,
      'position': resultat.position,
      'points': resultat.points,
      'heure_arrivee': resultat.heureArrivee?.toUtc().toIso8601String(),
      'temps_total_millisecondes': resultat.tempsTotalMillisecondes,
      'ecart_premier_millisecondes': resultat.ecartPremierMillisecondes,
      'statut': _convertirStatutPourSupabase(resultat.statut),
      'commentaire': resultat.commentaire,
      'date_publication': resultat.datePublication?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _convertirPourModification(Resultat resultat) {
    return {
      'position': resultat.position,
      'points': resultat.points,
      'heure_arrivee': resultat.heureArrivee?.toUtc().toIso8601String(),
      'temps_total_millisecondes': resultat.tempsTotalMillisecondes,
      'ecart_premier_millisecondes': resultat.ecartPremierMillisecondes,
      'statut': _convertirStatutPourSupabase(resultat.statut),
      'commentaire': resultat.commentaire,
      'date_publication': resultat.datePublication?.toUtc().toIso8601String(),
    };
  }

  String _convertirStatutPourSupabase(StatutResultat statut) {
    switch (statut) {
      case StatutResultat.arrive:
        return 'arrive';

      case StatutResultat.horsDelai:
        return 'hors_delai';

      case StatutResultat.abandon:
        return 'abandon';

      case StatutResultat.disqualifie:
        return 'disqualifie';
    }
  }

  int _comparerResultats(Resultat resultatA, Resultat resultatB) {
    final positionA = resultatA.position;
    final positionB = resultatB.position;

    if (positionA != null && positionB == null) {
      return -1;
    }

    if (positionA == null && positionB != null) {
      return 1;
    }

    if (positionA != null && positionB != null) {
      return positionA.compareTo(positionB);
    }

    return resultatA.athlete.nomComplet.toLowerCase().compareTo(
      resultatB.athlete.nomComplet.toLowerCase(),
    );
  }

  String _traduireErreurSupabase(PostgrestException exception) {
    final details = '${exception.message} ${exception.details}'.toLowerCase();

    if (exception.code == '23505') {
      if (details.contains('athlete_id')) {
        return 'Un résultat existe déjà pour cet athlète '
            'dans cette manche.';
      }

      if (details.contains('position')) {
        return 'Cette position est déjà attribuée '
            'dans la manche.';
      }

      return 'Ce résultat existe déjà.';
    }

    if (exception.code == '23503') {
      return 'La manche ou l’athlète est introuvable.';
    }

    if (exception.code == '23514') {
      return 'Les données du résultat sont invalides.';
    }

    if (exception.code == '42501') {
      return 'Tu n’as pas l’autorisation '
          'de modifier ces résultats.';
    }

    return 'Opération impossible sur le résultat : '
        '${exception.message}';
  }
}
