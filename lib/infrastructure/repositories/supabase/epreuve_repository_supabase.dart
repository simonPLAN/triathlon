import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/type_discipline.dart';
import '../../../domain/ports/epreuve_repository.dart';

class EpreuveRepositorySupabase implements EpreuveRepository {
  EpreuveRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const String _nomTable = 'epreuves';

  static const String _colonnes = '''
    id,
    competition_id,
    discipline,
    nom,
    distance_metres,
    nombre_manches,
    ordre,
    duree_limite_secondes,
    date_creation,
    date_modification
  ''';

  @override
  Future<List<Epreuve>> obtenirParCompetition(String competitionId) async {
    final idNettoye = competitionId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_colonnes)
          .eq('competition_id', idNettoye)
          .order('ordre', ascending: true);

      return donnees
          .map<Epreuve>(_convertirDepuisSupabase)
          .toList(growable: false);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de charger les épreuves : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<Epreuve?> obtenirParId(String id) async {
    final idNettoye = id.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_colonnes)
          .eq('id', idNettoye)
          .maybeSingle();

      if (donnees == null) {
        return null;
      }

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de récupérer l’épreuve : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<Epreuve> creer(Epreuve epreuve) async {
    try {
      final donnees = await _client
          .from(_nomTable)
          .insert(_convertirPourCreation(epreuve))
          .select(_colonnes)
          .single();

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(_messageErreurCreation(exception));
    }
  }

  @override
  Future<Epreuve> modifier(Epreuve epreuve) async {
    final idNettoye = epreuve.id.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .update(_convertirPourModification(epreuve))
          .eq('id', idNettoye)
          .select(_colonnes)
          .single();

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(_messageErreurModification(exception));
    }
  }

  @override
  Future<void> supprimer(String id) async {
    final idNettoye = id.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    try {
      await _client.from(_nomTable).delete().eq('id', idNettoye);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de supprimer l’épreuve : '
        '${exception.message}',
      );
    }
  }

  Epreuve _convertirDepuisSupabase(Map<String, dynamic> donnees) {
    return Epreuve(
      id: donnees['id'] as String,
      competitionId: donnees['competition_id'] as String,
      discipline: _convertirDisciplineDepuisSupabase(
        donnees['discipline'] as String,
      ),
      nom: donnees['nom'] as String,
      distanceMetres: donnees['distance_metres'] as int,
      nombreManches: donnees['nombre_manches'] as int,
      ordre: donnees['ordre'] as int,
      dureeLimiteSecondes: donnees['duree_limite_secondes'] as int,
      dateCreation: DateTime.parse(donnees['date_creation'] as String),
      dateModification: DateTime.parse(donnees['date_modification'] as String),
    );
  }

  Map<String, dynamic> _convertirPourCreation(Epreuve epreuve) {
    return {
      'competition_id': epreuve.competitionId,
      'discipline': _convertirDisciplinePourSupabase(epreuve.discipline),
      'nom': epreuve.nom,
      'distance_metres': epreuve.distanceMetres,
      'nombre_manches': epreuve.nombreManches,
      'ordre': epreuve.ordre,
      'duree_limite_secondes': epreuve.dureeLimiteSecondes,
    };
  }

  Map<String, dynamic> _convertirPourModification(Epreuve epreuve) {
    return {
      'discipline': _convertirDisciplinePourSupabase(epreuve.discipline),
      'nom': epreuve.nom,
      'distance_metres': epreuve.distanceMetres,
      'nombre_manches': epreuve.nombreManches,
      'ordre': epreuve.ordre,
      'duree_limite_secondes': epreuve.dureeLimiteSecondes,
    };
  }

  TypeDiscipline _convertirDisciplineDepuisSupabase(String discipline) {
    switch (discipline) {
      case 'natation':
        return TypeDiscipline.natation;

      case 'velo':
        return TypeDiscipline.velo;

      case 'course_a_pied':
        return TypeDiscipline.courseAPied;

      default:
        throw FormatException('Discipline inconnue : $discipline');
    }
  }

  String _convertirDisciplinePourSupabase(TypeDiscipline discipline) {
    switch (discipline) {
      case TypeDiscipline.natation:
        return 'natation';

      case TypeDiscipline.velo:
        return 'velo';

      case TypeDiscipline.courseAPied:
        return 'course_a_pied';
    }
  }

  String _messageErreurCreation(PostgrestException exception) {
    if (exception.code == '23505') {
      return 'Une épreuve utilise déjà cet ordre '
          'dans la compétition.';
    }

    if (exception.code == '23514') {
      return 'Les valeurs de l’épreuve ne respectent pas '
          'les règles de validation.';
    }

    return 'Impossible de créer l’épreuve : '
        '${exception.message}';
  }

  String _messageErreurModification(PostgrestException exception) {
    if (exception.code == '23505') {
      return 'Une autre épreuve utilise déjà cet ordre.';
    }

    if (exception.code == '23514') {
      return 'Les valeurs de l’épreuve ne respectent pas '
          'les règles de validation.';
    }

    return 'Impossible de modifier l’épreuve : '
        '${exception.message}';
  }
}
