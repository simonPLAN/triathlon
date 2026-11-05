import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/domain/entities/edition_resultat.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/entities/statut_resultat.dart';
import 'package:triathlon/infrastructure/repositories/supabase/edition_resultats_repository_supabase.dart';
import 'package:triathlon/infrastructure/repositories/supabase/manche_repository_supabase.dart';

void main() {
  for (final conflit in [false, true]) {
    test(
      'correction RPC unique, classement complet et conflit=$conflit',
      () async {
        final serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final client = SupabaseClient(
          'http://127.0.0.1:${serveur.port}',
          'cle-test',
        );
        addTearDown(() async {
          await client.dispose();
          await serveur.close(force: true);
        });
        final requete = serveur.first.then((request) async {
          expect(request.method, 'POST');
          expect(request.uri.path, '/rest/v1/rpc/editer_resultat_manche');
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['p_revision'], 7);
          expect(body['p_mode'], 'echanger');
          expect(body['p_temps_ms'], 62003);
          expect(body['p_accepter_depublication'], true);
          request.response.headers.contentType = ContentType.json;
          if (conflit) {
            request.response.statusCode = 409;
            request.response.write(
              jsonEncode({
                'code': '40001',
                'message': 'Classement périmé',
                'details': null,
                'hint': null,
              }),
            );
          } else {
            request.response.write(
              jsonEncode({
                'revision': 12,
                'depublies': true,
                'resultats': [
                  for (final i in [1, 2])
                    {
                      'id': 'r$i',
                      'manche_id': 'manche',
                      'athlete_id': 'a$i',
                      'position': i,
                      'points': 6 - i,
                      'statut': 'arrive',
                      'heure_arrivee': '2026-01-01T12:01:00Z',
                      'temps_total_millisecondes': 60000,
                      'ecart_premier_millisecondes': 0,
                      'date_creation': '2026-01-01T12:00:00Z',
                      'date_modification': '2026-01-01T12:02:00Z',
                      'date_publication': null,
                      'profils': {
                        'id': 'a$i',
                        'prenom': 'Athlète',
                        'nom': '$i',
                      },
                    },
                ],
              }),
            );
          }
          await request.response.close();
        });
        final resultat = EditionResultatsRepositorySupabase(client).editer(
          const ModificationResultat(
            mancheId: 'manche',
            athleteId: 'athlete',
            resultatId: 'resultat',
            revision: 7,
            statut: StatutResultat.arrive,
            mode: ModeReclassement.echanger,
            position: 2,
            tempsMillisecondes: 62003,
            accepterDepublication: true,
          ),
        );
        if (conflit) {
          await expectLater(
            resultat,
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains('Actualise'),
              ),
            ),
          );
        } else {
          final edition = await resultat;
          expect(edition.resultats.map((r) => r.id), ['r1', 'r2']);
          expect(edition.revision, 12);
          expect(edition.depublies, true);
          expect(edition.resultats.every((r) => !r.estPublie), true);
        }
        await requete;
      },
    );
  }
  test(
    'publication utilise la RPC avec révision et lit la nouvelle version',
    () async {
      final serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = SupabaseClient(
        'http://127.0.0.1:${serveur.port}',
        'cle-test',
      );
      addTearDown(() async {
        await client.dispose();
        await serveur.close(force: true);
      });
      final date = DateTime.utc(2026);
      final requete = serveur.first.then((request) async {
        expect(request.method, 'POST');
        expect(
          request.uri.path,
          '/rest/v1/rpc/publier_resultats_manche_verifies',
        );
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body['p_revision'], 12);
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'id': 'manche',
            'epreuve_id': 'epreuve',
            'numero': 1,
            'statut': 'terminee',
            'resultats_publies': true,
            'revision_resultats': 15,
            'date_creation': date.toIso8601String(),
            'date_modification': date.toIso8601String(),
          }),
        );
        await request.response.close();
      });
      final publiee = await MancheRepositorySupabase(client).modifier(
        Manche(
          id: 'manche',
          epreuveId: 'epreuve',
          numero: 1,
          statut: StatutManche.terminee,
          resultatsPublies: true,
          revisionResultats: 12,
          dateCreation: date,
          dateModification: date,
        ),
      );
      await requete;
      expect(publiee.resultatsPublies, true);
      expect(publiee.revisionResultats, 15);
    },
  );
}
