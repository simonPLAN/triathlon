import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/presentation/controllers/competition_controller.dart';
import 'package:triathlon/presentation/controllers/competitions_ouvertes_controller.dart';
import 'package:triathlon/presentation/controllers/epreuve_controller.dart';
import 'package:triathlon/presentation/controllers/inscription_controller.dart';
import 'package:triathlon/presentation/controllers/manche_controller.dart';
import 'package:triathlon/presentation/controllers/resultat_controller.dart';

import 'application/use_cases/connecter_utilisateur.dart';
import 'configuration/identite_application.dart';
import 'application/use_cases/auth/supprimer_mon_compte.dart';
import 'application/use_cases/deconnecter_utilisateur.dart';
import 'application/use_cases/inscrire_athlete.dart';
import 'application/use_cases/obtenir_profil_connecte.dart';
import 'presentation/controllers/athlete_controller.dart';
import 'presentation/pages/auth_gate.dart';
import 'domain/ports/source_liens_recuperation.dart';
import 'presentation/controllers/recuperation_compte_controller.dart';
import 'presentation/navigation/recuperation_compte_host.dart';
import 'presentation/theme/theme_application.dart';

class TriathlonApp extends StatefulWidget {
  const TriathlonApp({
    super.key,
    required this.clientSupabase,
    required this.athleteController,
    required this.competitionController,
    required this.inscriptionController,
    required this.connecterUtilisateur,
    required this.deconnecterUtilisateur,
    required this.inscrireAthlete,
    required this.obtenirProfilConnecte,
    required this.competitionsOuvertesController,
    required this.epreuveController,
    required this.mancheController,
    required this.resultatController,
    required this.recuperationCompte,
    required this.sourceLiensRecuperation,
    required this.supprimerMonCompte,
  });

  final SupabaseClient clientSupabase;
  final AthleteController athleteController;
  final CompetitionController competitionController;
  final ConnecterUtilisateur connecterUtilisateur;
  final DeconnecterUtilisateur deconnecterUtilisateur;
  final InscrireAthlete inscrireAthlete;
  final ObtenirProfilConnecte obtenirProfilConnecte;
  final InscriptionController inscriptionController;
  final CompetitionsOuvertesController competitionsOuvertesController;
  final EpreuveController epreuveController;
  final MancheController mancheController;
  final ResultatController resultatController;

  final RecuperationCompteController recuperationCompte;
  final SourceLiensRecuperation sourceLiensRecuperation;
  final SupprimerMonCompte supprimerMonCompte;

  @override
  State<TriathlonApp> createState() => _TriathlonAppState();
}

class _TriathlonAppState extends State<TriathlonApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return RecuperationCompteHost(
      controller: widget.recuperationCompte,
      sourceLiens: widget.sourceLiensRecuperation,
      navigatorKey: _navigatorKey,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: IdentiteApplication.nom,
        theme: ThemeApplication.clair,
        darkTheme: ThemeApplication.sombre,
        themeMode: ThemeMode.system,
        home: AuthGate(
          supprimerMonCompte: widget.supprimerMonCompte,
          recuperationCompte: widget.recuperationCompte,
          clientSupabase: widget.clientSupabase,
          athleteController: widget.athleteController,
          competitionController: widget.competitionController,
          connecterUtilisateur: widget.connecterUtilisateur,
          deconnecterUtilisateur: widget.deconnecterUtilisateur,
          inscrireAthlete: widget.inscrireAthlete,
          obtenirProfilConnecte: widget.obtenirProfilConnecte,
          inscriptionController: widget.inscriptionController,
          competitionsOuvertesController: widget.competitionsOuvertesController,
          epreuveController: widget.epreuveController,
          mancheController: widget.mancheController,
          resultatController: widget.resultatController,
        ),
      ),
    );
  }
}
