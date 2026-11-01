import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'application/use_cases/ajouter_athlete.dart';
import 'application/use_cases/connecter_utilisateur.dart';
import 'application/use_cases/deconnecter_utilisateur.dart';
import 'application/use_cases/inscrire_athlete.dart';
import 'application/use_cases/lister_athletes.dart';
import 'infrastructure/repositories/supabase/athlete_repository_supabase.dart';
import 'infrastructure/repositories/supabase/auth_repository_supabase.dart';
import 'presentation/controllers/athlete_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dgjtfhslcbrgsdczlvdg.supabase.co',
    publishableKey: 'sb_publishable_YkkAvzFAOUZKJQwUxZKl-A_HJsJLBWT',
  );

  final clientSupabase = Supabase.instance.client;

  final athleteRepository = AthleteRepositorySupabase(clientSupabase);

  final authRepository = AuthRepositorySupabase(clientSupabase);

  final athleteController = AthleteController(
    ajouterAthlete: AjouterAthlete(athleteRepository),
    listerAthletes: ListerAthletes(athleteRepository),
  );

  runApp(
    TriathlonApp(
      clientSupabase: clientSupabase,
      athleteController: athleteController,
      connecterUtilisateur: ConnecterUtilisateur(authRepository),
      deconnecterUtilisateur: DeconnecterUtilisateur(authRepository),
      inscrireAthlete: InscrireAthlete(authRepository),
    ),
  );
}
