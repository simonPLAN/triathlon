import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'composition/assembler_application.dart';
import 'infrastructure/auth/configuration_authentification.dart';
import 'infrastructure/auth/liens_recuperation_app_links.dart';
import 'infrastructure/auth/liens_recuperation_web.dart';
import 'presentation/pages/demarrage_application.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DemarrageApplication(charger: _initialiser));
}

Future<Widget> _initialiser() async {
  final configuration = ConfigurationAuthentification.environnement();
  final stockageAuth = SharedPreferencesLocalStorage(
    persistSessionKey:
        'sb-${Uri.parse(configuration.urlSupabase).host.split('.').first}-auth-token',
  );
  await Supabase.initialize(
    debug: kDebugMode,
    url: configuration.urlSupabase,
    publishableKey: configuration.clePublique,
    authOptions: FlutterAuthClientOptions(
      localStorage: stockageAuth,
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: false,
    ),
  );
  return assemblerApplication(
    clientSupabase: Supabase.instance.client,
    configuration: configuration,
    stockageAuth: stockageAuth,
    sourceLiens: kIsWeb ? LiensRecuperationWeb() : LiensRecuperationAppLinks(),
  );
}
