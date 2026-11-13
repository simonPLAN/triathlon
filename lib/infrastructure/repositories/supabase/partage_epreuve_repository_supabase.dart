import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/partage_epreuve.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/entities/type_discipline.dart';
import '../../../domain/ports/partage_epreuve_repository.dart';

class PartageEpreuveRepositorySupabase implements PartageEpreuveRepository {
  PartageEpreuveRepositorySupabase(this._client);
  final SupabaseClient _client;

  Future<dynamic> _rpc(String nom, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(nom, params: params);
    } on PostgrestException catch (erreur) {
      if (erreur.code == 'PGRST202') {
        throw StateError(
          'Le partage des épreuves doit être activé sur le serveur.',
        );
      }
      throw StateError(erreur.message);
    }
  }

  @override
  Future<List<CoachAutoriseEpreuve>> listerCoachs(String epreuveId) async {
    final lignes = await _rpc('lister_coachs_epreuve', {
      'p_epreuve_id': epreuveId,
    }) as List;
    return lignes
        .map(
          (ligne) => CoachAutoriseEpreuve(
            id: ligne['id'] as String,
            pseudo: ligne['pseudo'] as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> autoriser(String epreuveId, String pseudo) async {
    await _rpc('autoriser_coach_epreuve', {
      'p_epreuve_id': epreuveId,
      'p_pseudo': pseudo,
    });
  }

  @override
  Future<void> retirer(String epreuveId, String coachId) async {
    await _rpc('retirer_coach_epreuve', {
      'p_epreuve_id': epreuveId,
      'p_coach_id': coachId,
    });
  }

  @override
  Future<List<Inscription>> listerParticipants(String mancheId) async {
    final lignes = await _rpc('lister_participants_manche_delegue', {
      'p_manche_id': mancheId,
    }) as List;
    return lignes
        .map(
          (ligne) => Inscription(
            id: ligne['id'] as String,
            competitionId: ligne['competition_id'] as String,
            athlete: Athlete(
              id: ligne['athlete_id'] as String,
              pseudo: ligne['pseudo'] as String,
            ),
            numeroDossard: ligne['numero_dossard'] as int?,
            dateInscription: DateTime.parse(
              ligne['date_inscription'] as String,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<EpreuvePartagee>> listerPartagees() async {
    final lignes = await _rpc('lister_epreuves_partagees', {}) as List;
    return lignes
        .map((ligne) {
          final e = Map<String, dynamic>.from(ligne['epreuve'] as Map);
          final c = Map<String, dynamic>.from(ligne['competition'] as Map);
          return EpreuvePartagee(
            epreuve: Epreuve(
              id: e['id'] as String,
              competitionId: e['competition_id'] as String,
              discipline: switch (e['discipline']) {
                'natation' => TypeDiscipline.natation,
                'velo' => TypeDiscipline.velo,
                'course_a_pied' => TypeDiscipline.courseAPied,
                _ => throw const FormatException('Discipline inconnue.'),
              },
              nom: e['nom'] as String,
              distanceMetres: e['distance_metres'] as int,
              nombreManches: e['nombre_manches'] as int,
              ordre: e['ordre'] as int,
              dureeLimiteSecondes: e['duree_limite_secondes'] as int,
              dateCreation: DateTime.parse(e['date_creation'] as String),
              dateModification: DateTime.parse(
                e['date_modification'] as String,
              ),
            ),
            competition: Competition(
              id: c['id'] as String,
              nom: c['nom'] as String,
              description: c['description'] as String?,
              lieu: c['lieu'] as String?,
              dateCompetition: DateTime.parse(c['date_competition'] as String),
              coachId: c['coach_id'] as String,
              statut: switch (c['statut']) {
                'brouillon' => StatutCompetition.brouillon,
                'ouverte' => StatutCompetition.ouverte,
                'en_cours' => StatutCompetition.enCours,
                'terminee' => StatutCompetition.terminee,
                'annulee' => StatutCompetition.annulee,
                _ => throw const FormatException('Statut inconnu.'),
              },
              dateCreation: DateTime.parse(c['date_creation'] as String),
              dateModification: DateTime.parse(
                c['date_modification'] as String,
              ),
              demarrageAutomatiqueMancheSuivante:
                  c['demarrage_automatique_manche_suivante'] == true,
            ),
          );
        })
        .toList(growable: false);
  }
}
