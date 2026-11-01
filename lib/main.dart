import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/presentation/controllers/competition_controller.dart';

import 'app.dart';
import 'application/use_cases/ajouter_athlete.dart';
import 'application/use_cases/competition/changer_statut_competition.dart';
import 'application/use_cases/competition/creer_competition.dart';
import 'application/use_cases/competition/lister_competitions.dart';
import 'application/use_cases/competition/modifier_competition.dart';
import 'application/use_cases/competition/supprimer_competition.dart';
import 'application/use_cases/connecter_utilisateur.dart';
import 'application/use_cases/deconnecter_utilisateur.dart';
import 'application/use_cases/inscrire_athlete.dart';
import 'application/use_cases/lister_athletes.dart';
import 'application/use_cases/obtenir_profil_connecte.dart';
import 'infrastructure/repositories/supabase/athlete_repository_supabase.dart';
import 'infrastructure/repositories/supabase/auth_repository_supabase.dart';
import 'infrastructure/repositories/supabase/competition_repository_supabase.dart';
import 'infrastructure/repositories/supabase/profil_repository_supabase.dart';
import 'presentation/controllers/athlete_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dgjtfhslcbrgsdczlvdg.supabase.co',
    publishableKey: 'sb_publishable_YkkAvzFAOUZKJQwUxZKl-A_HJsJLBWT',
  );

  final clientSupabase = Supabase.instance.client;
  final competitionRepository = CompetitionRepositorySupabase(clientSupabase);

  final competitionController = CompetitionController(
    CreerCompetition(competitionRepository),
    ListerCompetitions(competitionRepository),
    ModifierCompetition(competitionRepository),
    ChangerStatutCompetition(competitionRepository),
    SupprimerCompetition(competitionRepository),
  );
  final athleteRepository = AthleteRepositorySupabase(clientSupabase);

  final authRepository = AuthRepositorySupabase(clientSupabase);

  final athleteController = AthleteController(
    ajouterAthlete: AjouterAthlete(athleteRepository),
    listerAthletes: ListerAthletes(athleteRepository),
  );

  final profilRepository = ProfilRepositorySupabase(clientSupabase);

  runApp(
    TriathlonApp(
      clientSupabase: clientSupabase,
      athleteController: athleteController,
      competitionController: competitionController,
      connecterUtilisateur: ConnecterUtilisateur(authRepository),
      deconnecterUtilisateur: DeconnecterUtilisateur(authRepository),
      inscrireAthlete: InscrireAthlete(authRepository),
      obtenirProfilConnecte: ObtenirProfilConnecte(profilRepository),
    ),
  );
}
