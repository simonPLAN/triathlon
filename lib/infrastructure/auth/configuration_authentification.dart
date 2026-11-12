import 'dart:convert';

import 'package:flutter/foundation.dart';

class ConfigurationAuthentification {
  ConfigurationAuthentification({
    required this.environnement,
    required this.urlSupabase,
    required this.clePublique,
    bool release = false,
    String flavor = '',
    String productionHost = hoteProduction,
  }) {
    if (!{'production', 'staging'}.contains(environnement)) {
      throw ArgumentError('APP_ENV doit être production ou staging.');
    }
    if (flavor.isNotEmpty && flavor != environnement) {
      throw ArgumentError(
        'La variante Android et APP_ENV doivent correspondre.',
      );
    }
    if (urlSupabase.isEmpty || clePublique.isEmpty) {
      throw ArgumentError(
        'Configurer SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    final uri = Uri.tryParse(urlSupabase);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError('L’URL Supabase doit désigner la racine du serveur.');
    }
    if (release && uri.scheme != 'https') {
      throw ArgumentError('HTTPS est obligatoire en Release.');
    }
    if (environnement == 'staging' && uri.host == productionHost) {
      throw ArgumentError(
        'Staging doit utiliser un projet Supabase distinct de la production.',
      );
    }
    if (release &&
        environnement == 'production' &&
        uri.host != productionHost) {
      throw ArgumentError(
        'Le projet Supabase ne correspond pas à la production.',
      );
    }
    final role = _roleJwt(clePublique);
    if (clePublique.startsWith('sb_secret_') || role == 'service_role') {
      throw ArgumentError(
        'Une clé privilégiée ne doit jamais être intégrée dans l’application.',
      );
    }
    if (release &&
        !clePublique.startsWith('sb_publishable_') &&
        role != 'anon') {
      throw ArgumentError('Une clé publique publishable ou anon est requise.');
    }
  }

  static const hoteProduction = 'dgjtfhslcbrgsdczlvdg.supabase.co';

  factory ConfigurationAuthentification.environnement() =>
      ConfigurationAuthentification.depuisParametres(
        environnement: const String.fromEnvironment('APP_ENV'),
        url: const String.fromEnvironment('SUPABASE_URL'),
        cle: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        flavor: const String.fromEnvironment('FLUTTER_APP_FLAVOR'),
        release: kReleaseMode,
      );

  factory ConfigurationAuthentification.depuisParametres({
    String environnement = '',
    String url = '',
    String cle = '',
    String flavor = '',
    bool release = false,
  }) {
    if (release && (environnement.isEmpty || url.isEmpty || cle.isEmpty)) {
      throw ArgumentError(
        'Une Release exige APP_ENV, SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY explicites.',
      );
    }
    if (url.isEmpty != cle.isEmpty) {
      throw ArgumentError(
        'L’URL et la clé publique Supabase doivent être fournies ensemble.',
      );
    }
    final choix = environnement.isNotEmpty
        ? environnement
        : (flavor.isNotEmpty ? flavor : 'production');
    return ConfigurationAuthentification(
      environnement: choix,
      urlSupabase: url.isNotEmpty
          ? url
          : (choix == 'production' ? 'https://$hoteProduction' : ''),
      clePublique: cle.isNotEmpty
          ? cle
          : (choix == 'production'
                ? 'sb_publishable_YkkAvzFAOUZKJQwUxZKl-A_HJsJLBWT'
                : ''),
      release: release,
      flavor: flavor,
    );
  }

  static String? _roleJwt(String cle) {
    try {
      final morceaux = cle.split('.');
      if (morceaux.length != 3) return null;
      final donnees = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(morceaux[1]))),
      );
      return donnees is Map ? donnees['role'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  final String environnement;
  final String urlSupabase;
  final String clePublique;
  Uri get redirection => kIsWeb
      ? Uri.base
            .resolve(
              const String.fromEnvironment('WEB_BASE_PATH', defaultValue: '/'),
            )
            .resolve('auth/reset-password')
      : Uri.parse(
          '${environnement == 'staging' ? 'triathlon-staging' : 'triathlon'}://auth/reset-password',
        );
}
