import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/infrastructure/repositories/supabase/manche_repository_supabase.dart';

Manche mancheEnCours(DateTime depart) => Manche(
  id: 'manche',
  epreuveId: 'epreuve',
  numero: 1,
  statut: StatutManche.enCours,
  resultatsPublies: false,
  heureDepart: depart,
  dateCreation: depart,
  dateModification: depart,
);

void main() {
  test('le délai après la première arrivée est exactement de 60 secondes', () {
    final depart = DateTime.parse('2026-07-10T12:00:00+02:00');
    final arrivee = DateTime.parse('2026-07-10T12:05:00+02:00');
    final manche = mancheEnCours(depart).enregistrerPremiereArrivee(
      heureArrivee: arrivee,
      dureeLimiteSecondes: 60,
    );
    expect(
      manche.heureFinDelai!.difference(arrivee),
      const Duration(seconds: 60),
    );
    expect(manche.heureFinDelai!.toUtc(), DateTime.utc(2026, 7, 10, 10, 6));
  });

  test(
    'refuse une arrivée avant le départ plutôt que de déplacer le délai',
    () {
      final depart = DateTime.utc(2026, 7, 10, 10);
      expect(
        () => mancheEnCours(depart).enregistrerPremiereArrivee(
          heureArrivee: depart.subtract(const Duration(seconds: 1)),
          dureeLimiteSecondes: 60,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'les horaires locaux partent en UTC et conservent le délai au retour',
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
      final depart = DateTime(2026, 7, 10, 12);
      final arrivee = depart.add(const Duration(minutes: 5));
      final manche = mancheEnCours(depart).enregistrerPremiereArrivee(
        heureArrivee: arrivee,
        dureeLimiteSecondes: 60,
      );
      final requete = serveur.first.then((request) async {
        final data = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        expect(request.method, 'PATCH');
        for (final champ in [
          'heure_depart',
          'heure_premiere_arrivee',
          'heure_fin_delai',
        ]) {
          expect(data[champ] as String, endsWith('Z'), reason: champ);
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            ...data,
            'id': 'manche',
            'epreuve_id': 'epreuve',
            'numero': 1,
            'date_creation': depart.toUtc().toIso8601String(),
            'date_modification': depart.toUtc().toIso8601String(),
          }),
        );
        await request.response.close();
      });
      final rechargee = await MancheRepositorySupabase(client).modifier(manche);
      await requete;
      expect(rechargee.heureDepart!.isAtSameMomentAs(depart), isTrue);
      expect(
        rechargee.heureFinDelai!.difference(arrivee),
        const Duration(seconds: 60),
      );
    },
  );
}
