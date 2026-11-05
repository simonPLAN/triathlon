import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/entities/type_discipline.dart';
import 'package:triathlon/infrastructure/repositories/supabase/programme_competition_repository_supabase.dart';

void main() {
  for (final refuse in [false, true]) {
    test('programme RPC lecture seule et accès refusé=$refuse', () async {
      final serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = SupabaseClient(
        'http://127.0.0.1:${serveur.port}',
        'cle-test',
      );
      addTearDown(() async {
        await client.dispose();
        await serveur.close(force: true);
      });
      final expiration =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      String encoder(Object valeur) =>
          base64Url.encode(utf8.encode(jsonEncode(valeur))).replaceAll('=', '');
      final token =
          '${encoder({'alg': 'HS256', 'typ': 'JWT'})}.${encoder({'exp': expiration, 'sub': 'athlete'})}.signature';
      await client.auth.setInitialSession(
        jsonEncode({
          'access_token': token,
          'refresh_token': 'refresh-test',
          'token_type': 'bearer',
          'expires_in': 3600,
          'expires_at': expiration,
          'user': {
            'id': 'athlete',
            'aud': 'authenticated',
            'created_at': '2026-01-01T00:00:00Z',
            'app_metadata': {},
            'user_metadata': {},
          },
        }),
      );
      final requete = serveur.first.then((request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/rest/v1/rpc/programme_competition_athlete');
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'p_competition_id': 'competition',
        });
        request.response.headers.contentType = ContentType.json;
        if (refuse) {
          request.response.statusCode = 403;
          request.response.write(
            jsonEncode({
              'code': '42501',
              'message': 'Accès interdit',
              'details': null,
              'hint': null,
            }),
          );
        } else {
          request.response.write(
            jsonEncode({
              'affectations_disponibles': true,
              'epreuves': [
                {
                  'id': 'epreuve',
                  'nom': 'Course',
                  'discipline': 'course_a_pied',
                  'distance_metres': 5000,
                  'ordre': 3,
                  'manches': [
                    {
                      'id': 'm1',
                      'numero': 1,
                      'statut': 'a_venir',
                      'participe': true,
                      'ordre_depart': 2,
                    },
                    {
                      'id': 'm2',
                      'numero': 2,
                      'statut': 'annulee',
                      'participe': null,
                      'ordre_depart': null,
                    },
                  ],
                },
              ],
            }),
          );
        }
        await request.response.close();
      });
      final lecture = ProgrammeCompetitionRepositorySupabase(client)
          .obtenir('competition');
      if (refuse) {
        await expectLater(
          lecture,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('pas accessible'),
            ),
          ),
        );
      } else {
        final programme = await lecture;
        expect(programme.affectationsDisponibles, true);
        expect(
          programme.epreuves.single.discipline,
          TypeDiscipline.courseAPied,
        );
        expect(programme.epreuves.single.distanceMetres, 5000);
        expect(programme.epreuves.single.manches.first.participe, true);
        expect(programme.epreuves.single.manches.first.ordreDepart, 2);
        expect(
          programme.epreuves.single.manches.last.statut,
          StatutManche.annulee,
        );
        expect(programme.epreuves.single.manches.last.participe, isNull);
      }
      await requete;
    });
  }
  test('aucun appel anonyme pour consulter le programme', () async {
    final client = SupabaseClient('https://example.supabase.co', 'cle-test');
    addTearDown(client.dispose);
    await expectLater(
      ProgrammeCompetitionRepositorySupabase(client).obtenir('competition'),
      throwsStateError,
    );
  });
}
