import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/programme_competition.dart';
import '../../../domain/entities/statut_manche.dart';
import '../../../domain/entities/type_discipline.dart';
import '../../../domain/ports/programme_competition_repository.dart';

class ProgrammeCompetitionRepositorySupabase
    implements ProgrammeCompetitionRepository {
  ProgrammeCompetitionRepositorySupabase(this._client);
  final SupabaseClient _client;

  @override
  Future<ProgrammeCompetition> obtenir(String competitionId) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Connecte-toi pour consulter le programme.');
    }
    try {
      final data = await _client.rpc(
        'programme_competition_athlete',
        params: {'p_competition_id': competitionId},
      ) as Map;
      return ProgrammeCompetition(
        affectationsDisponibles: data['affectations_disponibles'] == true,
        epreuves: (data['epreuves'] as List)
            .map(
              (e) => EpreuveProgramme(
                id: e['id'] as String,
                nom: e['nom'] as String,
                discipline: switch (e['discipline']) {
                  'natation' => TypeDiscipline.natation,
                  'velo' => TypeDiscipline.velo,
                  'course_a_pied' => TypeDiscipline.courseAPied,
                  _ => throw const FormatException('Discipline inconnue.'),
                },
                distanceMetres: (e['distance_metres'] as num).toInt(),
                ordre: (e['ordre'] as num).toInt(),
                manches: (e['manches'] as List)
                    .map(
                      (m) => MancheProgramme(
                        id: m['id'] as String,
                        numero: (m['numero'] as num).toInt(),
                        statut: switch (m['statut']) {
                          'a_venir' => StatutManche.aVenir,
                          'en_cours' => StatutManche.enCours,
                          'terminee' => StatutManche.terminee,
                          'annulee' => StatutManche.annulee,
                          _ => throw const FormatException(
                            'Statut de manche inconnu.',
                          ),
                        },
                        participe: m['participe'] as bool?,
                        ordreDepart: (m['ordre_depart'] as num?)?.toInt(),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        throw StateError('Le programme doit être activé sur le serveur.');
      }
      if (e.code == '42501') {
        throw StateError(
          'Ce programme n’est pas accessible. Vérifie ton inscription et actualise tes compétitions.',
        );
      }
      throw StateError(
        'Impossible de charger le programme. Réessaie dans quelques instants.',
      );
    } catch (_) {
      throw StateError(
        'Impossible de charger le programme. Vérifie ta connexion puis réessaie.',
      );
    }
  }
}
