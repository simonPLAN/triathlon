import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/presentation/controllers/competition_controller.dart';
import 'package:triathlon/presentation/controllers/competitions_ouvertes_controller.dart';
import 'package:triathlon/presentation/controllers/epreuve_controller.dart';
import 'package:triathlon/presentation/controllers/inscription_controller.dart';
import 'package:triathlon/presentation/controllers/manche_controller.dart';

import 'application/use_cases/connecter_utilisateur.dart';
import 'application/use_cases/deconnecter_utilisateur.dart';
import 'application/use_cases/inscrire_athlete.dart';
import 'application/use_cases/obtenir_profil_connecte.dart';
import 'presentation/controllers/athlete_controller.dart';
import 'presentation/pages/auth_gate.dart';

class TriathlonApp extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Compétition sportive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AuthGate(
        clientSupabase: clientSupabase,
        athleteController: athleteController,
        competitionController: competitionController,
        connecterUtilisateur: connecterUtilisateur,
        deconnecterUtilisateur: deconnecterUtilisateur,
        inscrireAthlete: inscrireAthlete,
        obtenirProfilConnecte: obtenirProfilConnecte,
        inscriptionController: inscriptionController,
        competitionsOuvertesController: competitionsOuvertesController,
        epreuveController: epreuveController,
        mancheController: mancheController,
      ),
    );
  }
}
