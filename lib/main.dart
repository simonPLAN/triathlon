import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/presentation/controllers/competition_controller.dart';
import 'package:triathlon/presentation/controllers/competitions_ouvertes_controller.dart';
import 'package:triathlon/presentation/controllers/epreuve_controller.dart';
import 'package:triathlon/presentation/controllers/inscription_controller.dart';
import 'package:triathlon/presentation/controllers/manche_controller.dart';
import 'package:triathlon/presentation/controllers/resultat_controller.dart';

import 'app.dart';
import 'infrastructure/repositories/supabase/edition_resultats_repository_supabase.dart';
import 'application/use_cases/auth/supprimer_mon_compte.dart';
import 'infrastructure/repositories/supabase/suppression_compte_repository_supabase.dart';
import 'application/use_cases/auth/recuperer_compte.dart';
import 'domain/services/lien_recuperation.dart';
import 'infrastructure/auth/liens_recuperation_app_links.dart';
import 'infrastructure/auth/configuration_authentification.dart';
import 'infrastructure/repositories/supabase/recuperation_compte_repository_supabase.dart';
import 'presentation/controllers/recuperation_compte_controller.dart';
import 'application/use_cases/epreuve/verifier_competition_brouillon.dart';
import 'application/use_cases/epreuve/configurer_epreuves.dart';
import 'application/use_cases/competition/suivre_competitions_athlete.dart';
import 'infrastructure/repositories/supabase/suivi_athlete_repository_supabase.dart';
import 'application/use_cases/inscription/inscrire_invite.dart';
import 'infrastructure/repositories/supabase/invite_repository_supabase.dart';
import 'application/use_cases/ajouter_athlete.dart';
import 'application/use_cases/competition/changer_statut_competition.dart';
import 'application/use_cases/competition/creer_competition.dart';
import 'application/use_cases/competition/lister_competitions.dart';
import 'application/use_cases/competition/lister_competitions_ouvertes.dart';
import 'application/use_cases/competition/modifier_competition.dart';
import 'application/use_cases/competition/supprimer_competition.dart';
import 'application/use_cases/connecter_utilisateur.dart';
import 'application/use_cases/deconnecter_utilisateur.dart';
import 'application/use_cases/epreuve/creer_epreuve.dart';
import 'application/use_cases/epreuve/lister_epreuves.dart';
import 'application/use_cases/inscription/desinscrire_athlete_competition.dart';
import 'application/use_cases/inscription/inscrire_athlete_competition.dart';
import 'application/use_cases/inscription/inscrire_utilisateur_connecte.dart';
import 'application/use_cases/inscription/lister_inscriptions.dart';
import 'application/use_cases/inscription/modifier_dossard_inscription.dart';
import 'application/use_cases/inscription/obtenir_inscription_utilisateur_connecte.dart';
import 'application/use_cases/inscrire_athlete.dart';
import 'application/use_cases/lister_athletes.dart';
import 'application/use_cases/manche/annuler_manche.dart';
import 'application/use_cases/manche/demarrer_manche.dart';
import 'application/use_cases/manche/enregistrer_premiere_arrivee.dart';
import 'application/use_cases/manche/generer_manches_pour_epreuve.dart';
import 'application/use_cases/manche/lister_manches.dart';
import 'application/use_cases/manche/publier_resultats_manche.dart';
import 'application/use_cases/manche/terminer_manche.dart';
import 'application/use_cases/obtenir_profil_connecte.dart';
import 'application/use_cases/resultat/enregistrer_arrivee.dart';
import 'application/use_cases/resultat/corriger_resultat.dart';
import 'application/use_cases/resultat/lister_resultats_manche.dart';
import 'application/use_cases/resultat/marquer_athletes_hors_delai.dart';
import 'domain/services/calcul_points.dart';
import 'infrastructure/repositories/supabase/athlete_repository_supabase.dart';
import 'infrastructure/repositories/supabase/auth_repository_supabase.dart';
import 'infrastructure/repositories/supabase/competition_repository_supabase.dart';
import 'infrastructure/repositories/supabase/epreuve_repository_supabase.dart';
import 'infrastructure/repositories/supabase/inscription_repository_supabase.dart';
import 'infrastructure/repositories/supabase/manche_repository_supabase.dart';
import 'infrastructure/repositories/supabase/profil_repository_supabase.dart';
import 'infrastructure/repositories/supabase/resultat_repository_supabase.dart';
import 'presentation/controllers/athlete_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configuration = ConfigurationAuthentification.environnement();
  final sourceLiens = LiensRecuperationAppLinks();
  final stockageAuth = SharedPreferencesLocalStorage(
    persistSessionKey:
        'sb-${Uri.parse(configuration.urlSupabase).host.split('.').first}-auth-token',
  );
  await Supabase.initialize(
    url: configuration.urlSupabase,
    publishableKey: configuration.clePublique,
    authOptions: FlutterAuthClientOptions(
      localStorage: stockageAuth,
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: false,
    ),
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
  final epreuveRepository = EpreuveRepositorySupabase(clientSupabase);
  final mancheRepository = MancheRepositorySupabase(clientSupabase);
  final verifierConfiguration = VerifierCompetitionBrouillon(
    competitionRepository,
  );
  final epreuveController = EpreuveController(
    CreerEpreuve(epreuveRepository, verifierConfiguration),
    ListerEpreuves(epreuveRepository),
    ConfigurerEpreuves(
      epreuveRepository,
      mancheRepository,
      verifierConfiguration,
    ),
  );
  final mancheController = MancheController(
    GenererManchesPourEpreuve(mancheRepository),
    ListerManches(mancheRepository),
    DemarrerManche(mancheRepository),
    EnregistrerPremiereArrivee(mancheRepository),
    TerminerManche(mancheRepository),
    AnnulerManche(mancheRepository),
    PublierResultatsManche(mancheRepository),
  );
  final inscriptionController = InscriptionController(
    ListerInscriptions(inscriptionRepository),
    InscrireAthleteCompetition(inscriptionRepository),
    ModifierDossardInscription(inscriptionRepository),
    DesinscrireAthleteCompetition(inscriptionRepository),
    InscrireUtilisateurConnecte(inscriptionRepository),
    ObtenirInscriptionUtilisateurConnecte(inscriptionRepository),
    InscrireInvite(InviteRepositorySupabase(clientSupabase)),
  );
  final athleteController = AthleteController(
    ajouterAthlete: AjouterAthlete(athleteRepository),
    listerAthletes: ListerAthletes(athleteRepository),
  );
  final competitionsOuvertesController = CompetitionsOuvertesController(
    ListerCompetitionsOuvertes(competitionRepository),
    SuivreCompetitionsAthlete(SuiviAthleteRepositorySupabase(clientSupabase)),
  );
  final calculPoints = CalculPoints();
  final resultatRepository = ResultatRepositorySupabase(clientSupabase);
  final resultatController = ResultatController(
    ListerResultatsManche(resultatRepository),
    EnregistrerArrivee(resultatRepository, calculPoints),
    CorrigerResultat(EditionResultatsRepositorySupabase(clientSupabase)),
    MarquerAthletesHorsDelai(resultatRepository),
  );
  final profilRepository = ProfilRepositorySupabase(clientSupabase);
  runApp(
    TriathlonApp(
      clientSupabase: clientSupabase,
      supprimerMonCompte: SupprimerMonCompte(
        SuppressionCompteRepositorySupabase(clientSupabase, stockageAuth),
      ),
      sourceLiensRecuperation: sourceLiens,
      recuperationCompte: RecuperationCompteController(
        RecupererCompte(
          RecuperationCompteRepositorySupabase(clientSupabase),
          LienRecuperation(configuration.redirection),
        ),
      ),
      athleteController: athleteController,
      competitionController: competitionController,
      inscriptionController: inscriptionController,
      connecterUtilisateur: ConnecterUtilisateur(authRepository),
      deconnecterUtilisateur: DeconnecterUtilisateur(authRepository),
      inscrireAthlete: InscrireAthlete(authRepository),
      obtenirProfilConnecte: ObtenirProfilConnecte(profilRepository),
      competitionsOuvertesController: competitionsOuvertesController,
      epreuveController: epreuveController,
      mancheController: mancheController,
      resultatController: resultatController,
    ),
  );
}
