import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/infrastructure/repositories/supabase/inscription_repository_supabase.dart';

void main() {
  for (final scenario in ['confirmee', 'aucune_ligne', 'interdite']) {
    test('désinscription HTTP : $scenario', () async {
      final serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = SupabaseClient(
        'http://127.0.0.1:${serveur.port}',
        'cle-publique-test',
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
        expect(request.method, 'DELETE');
        expect(request.uri.path, '/rest/v1/inscriptions');
        expect(request.uri.queryParameters['id'], 'eq.inscription');
        expect(request.uri.queryParameters['select'], 'id');
        request.response.headers.contentType = ContentType.json;
        if (scenario == 'interdite') {
          request.response.statusCode = 403;
          request.response.write(
            jsonEncode({
              'code': '42501',
              'message': 'Permission denied',
              'details': null,
              'hint': null,
            }),
          );
        } else {
          request.response.write(
            jsonEncode(
              scenario == 'confirmee'
                  ? [
                      {'id': 'inscription'},
                    ]
                  : [],
            ),
          );
        }
        await request.response.close();
      });
      final resultat = InscriptionRepositorySupabase(client)
          .desinscrire('inscription');
      if (scenario == 'confirmee') {
        await resultat;
      } else {
        await expectLater(
          resultat,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                scenario == 'interdite' ? 'autorisée' : 'pas été confirmée',
              ),
            ),
          ),
        );
      }
      await requete;
    });
  }
}
