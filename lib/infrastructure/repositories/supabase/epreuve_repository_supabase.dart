import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/type_discipline.dart';
import '../../../domain/ports/epreuve_repository.dart';

class EpreuveRepositorySupabase implements EpreuveRepository {
  EpreuveRepositorySupabase(this._client);
  final SupabaseClient _client;

  static const _colonnes =
      'id,competition_id,discipline,nom,distance_metres,'
      'nombre_manches,ordre,duree_limite_secondes,date_creation,date_modification';

  @override
  Future<List<Epreuve>> obtenirParCompetition(String competitionId) async {
    if (competitionId.trim().isEmpty) {
      throw ArgumentError('La compétition est obligatoire.');
    }
    final rows = await _client
        .from('epreuves')
        .select(_colonnes)
        .eq('competition_id', competitionId)
        .order('ordre');
    return rows.map(_convertir).toList();
  }

  @override
  Future<Epreuve?> obtenirParId(String id) async {
    if (id.trim().isEmpty) throw ArgumentError('L’épreuve est obligatoire.');
    final row = await _client
        .from('epreuves')
        .select(_colonnes)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _convertir(row);
  }

  @override
  Future<Epreuve> creer(Epreuve epreuve) =>
      _enregistrer(epreuve, creation: true);

  @override
  Future<Epreuve> modifier(Epreuve epreuve) =>
      _enregistrer(epreuve, creation: false);

  Future<Epreuve> _enregistrer(Epreuve e, {required bool creation}) async {
    final data = await _rpc('enregistrer_epreuve_configuree', {
      'p_id': creation ? null : e.id,
      'p_competition_id': e.competitionId,
      'p_nom': e.nom,
      'p_discipline': switch (e.discipline) {
        TypeDiscipline.natation => 'natation',
        TypeDiscipline.velo => 'velo',
        TypeDiscipline.courseAPied => 'course_a_pied',
      },
      'p_distance_metres': e.distanceMetres,
      'p_nombre_manches': e.nombreManches,
      'p_ordre': e.ordre,
      'p_duree_limite_secondes': e.dureeLimiteSecondes,
    });
    return _convertir(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> supprimer(String id) async {
    await _rpc('supprimer_epreuve_configuree', {'p_id': id});
  }

  @override
  Future<void> reordonner(String competitionId, List<String> epreuveIds) async {
    await _rpc('reordonner_epreuves_configurees', {
      'p_competition_id': competitionId,
      'p_ids': epreuveIds,
    });
  }

  Future<dynamic> _rpc(String fonction, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(fonction, params: params);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw StateError(
          'Cet ordre est déjà utilisé. Utilise les flèches pour réorganiser les épreuves.',
        );
      }
      if (e.code == 'PGRST202') {
        throw StateError(
          'La gestion des épreuves doit être activée sur le serveur.',
        );
      }
      throw StateError(e.message);
    }
  }

  Epreuve _convertir(Map<String, dynamic> m) => Epreuve(
    id: m['id'] as String,
    competitionId: m['competition_id'] as String,
    discipline: switch (m['discipline']) {
      'natation' => TypeDiscipline.natation,
      'velo' => TypeDiscipline.velo,
      'course_a_pied' => TypeDiscipline.courseAPied,
      _ => throw const FormatException('Discipline inconnue.'),
    },
    nom: m['nom'] as String,
    distanceMetres: m['distance_metres'] as int,
    nombreManches: m['nombre_manches'] as int,
    ordre: m['ordre'] as int,
    dureeLimiteSecondes: m['duree_limite_secondes'] as int,
    dateCreation: DateTime.parse(m['date_creation'] as String),
    dateModification: DateTime.parse(m['date_modification'] as String),
  );
}
