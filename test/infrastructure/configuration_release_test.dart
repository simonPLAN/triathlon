import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/infrastructure/auth/configuration_authentification.dart';

String jwt(String role) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role}))).replaceAll('=', '')}.signature';
void main() {
  test('Release exige une configuration explicite et interdit les secrets privilegies', () {
    expect(
      () => ConfigurationAuthentification.depuisParametres(release: true),
      throwsArgumentError,
    );
    for (final cle in ['sb_secret_TEST', jwt('service_role')]) {
      expect(
        () => ConfigurationAuthentification(
          environnement: 'production',
          urlSupabase:
              'https://${ConfigurationAuthentification.hoteProduction}',
          clePublique: cle,
          release: true,
          flavor: 'production',
        ),
        throwsArgumentError,
      );
    }
  });
  test('production explicite accepte uniquement le projet attendu et une cle publique', () {
    final configuration = ConfigurationAuthentification.depuisParametres(
      environnement: 'production',
      url: 'https://${ConfigurationAuthentification.hoteProduction}',
      cle: 'sb_publishable_TEST',
      flavor: 'production',
      release: true,
    );
    expect(
      configuration.redirection.toString(),
      'triathlon://auth/reset-password',
    );
    expect(
      () => ConfigurationAuthentification(
        environnement: 'production',
        urlSupabase: 'https://autre.supabase.co',
        clePublique: 'sb_publishable_TEST',
        release: true,
      ),
      throwsArgumentError,
    );
  });
  test('staging isole le projet, la variante et la redirection', () {
    final configuration = ConfigurationAuthentification.depuisParametres(
      environnement: 'staging',
      url: 'https://test.supabase.co',
      cle: jwt('anon'),
      flavor: 'staging',
      release: true,
    );
    expect(configuration.redirection.scheme, 'triathlon-staging');
    expect(
      () => ConfigurationAuthentification(
        environnement: 'staging',
        urlSupabase: 'https://${ConfigurationAuthentification.hoteProduction}',
        clePublique: 'sb_publishable_TEST',
      ),
      throwsArgumentError,
    );
    expect(
      () => ConfigurationAuthentification(
        environnement: 'production',
        urlSupabase: 'https://${ConfigurationAuthentification.hoteProduction}',
        clePublique: 'sb_publishable_TEST',
        flavor: 'staging',
      ),
      throwsArgumentError,
    );
  });
  test('Release refuse HTTP et une cle inconnue ; debug garde sa configuration existante', () {
    expect(
      () => ConfigurationAuthentification(
        environnement: 'production',
        urlSupabase: 'http://${ConfigurationAuthentification.hoteProduction}',
        clePublique: 'sb_publishable_TEST',
        release: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => ConfigurationAuthentification(
        environnement: 'production',
        urlSupabase: 'https://${ConfigurationAuthentification.hoteProduction}',
        clePublique: 'inconnue',
        release: true,
      ),
      throwsArgumentError,
    );
    expect(
      ConfigurationAuthentification.depuisParametres().environnement,
      'production',
    );
    expect(
      () => ConfigurationAuthentification.depuisParametres(
        url: 'https://test.supabase.co',
      ),
      throwsArgumentError,
    );
  });
}
