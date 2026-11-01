import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/presentation/controllers/competition_controller.dart';
import 'package:triathlon/presentation/controllers/competitions_ouvertes_controller.dart';
import 'package:triathlon/presentation/controllers/inscription_controller.dart';

import 'app.dart';
import 'application/use_cases/ajouter_athlete.dart';
import 'application/use_cases/competition/changer_statut_competition.dart';
import 'application/use_cases/competition/creer_competition.dart';
import 'application/use_cases/competition/lister_competitions.dart';
import 'application/use_cases/competition/lister_competitions_ouvertes.dart';
import 'application/use_cases/competition/modifier_competition.dart';
import 'application/use_cases/competition/supprimer_competition.dart';
import 'application/use_cases/connecter_utilisateur.dart';
import 'application/use_cases/deconnecter_utilisateur.dart';
import 'application/use_cases/inscription/desinscrire_athlete_competition.dart';
import 'application/use_cases/inscription/inscrire_athlete_competition.dart';
import 'application/use_cases/inscription/inscrire_utilisateur_connecte.dart';
import 'application/use_cases/inscription/lister_inscriptions.dart';
import 'application/use_cases/inscription/modifier_dossard_inscription.dart';
import 'application/use_cases/inscription/obtenir_inscription_utilisateur_connecte.dart';
import 'application/use_cases/inscrire_athlete.dart';
import 'application/use_cases/lister_athletes.dart';
import 'application/use_cases/obtenir_profil_connecte.dart';
import 'infrastructure/repositories/supabase/athlete_repository_supabase.dart';
import 'infrastructure/repositories/supabase/auth_repository_supabase.dart';
import 'infrastructure/repositories/supabase/competition_repository_supabase.dart';
import 'infrastructure/repositories/supabase/inscription_repository_supabase.dart';
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
  final inscriptionRepository = InscriptionRepositorySupabase(clientSupabase);
  final competitionController = CompetitionController(
    CreerCompetition(competitionRepository),
    ListerCompetitions(competitionRepository),
    ModifierCompetition(competitionRepository),
    ChangerStatutCompetition(competitionRepository),
    SupprimerCompetition(competitionRepository),
  );
  final athleteRepository = AthleteRepositorySupabase(clientSupabase);
  final authRepository = AuthRepositorySupabase(clientSupabase);

  final inscriptionController = InscriptionController(
    ListerInscriptions(inscriptionRepository),
    InscrireAthleteCompetition(inscriptionRepository),
    ModifierDossardInscription(inscriptionRepository),
    DesinscrireAthleteCompetition(inscriptionRepository),
    InscrireUtilisateurConnecte(inscriptionRepository),
    ObtenirInscriptionUtilisateurConnecte(inscriptionRepository),
  );
  final athleteController = AthleteController(
    ajouterAthlete: AjouterAthlete(athleteRepository),
    listerAthletes: ListerAthletes(athleteRepository),
  );
  final competitionsOuvertesController = CompetitionsOuvertesController(
    ListerCompetitionsOuvertes(competitionRepository),
  );
  final profilRepository = ProfilRepositorySupabase(clientSupabase);
  runApp(
    TriathlonApp(
      clientSupabase: clientSupabase,
      athleteController: athleteController,
      competitionController: competitionController,
      inscriptionController: inscriptionController,
      connecterUtilisateur: ConnecterUtilisateur(authRepository),
      deconnecterUtilisateur: DeconnecterUtilisateur(authRepository),
      inscrireAthlete: InscrireAthlete(authRepository),
      obtenirProfilConnecte: ObtenirProfilConnecte(profilRepository),
      competitionsOuvertesController: competitionsOuvertesController,
    ),
  );
}
