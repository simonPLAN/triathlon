import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'application/use_cases/connecter_utilisateur.dart';
import 'application/use_cases/deconnecter_utilisateur.dart';
import 'application/use_cases/inscrire_athlete.dart';
import 'presentation/controllers/athlete_controller.dart';
import 'presentation/pages/auth_gate.dart';

class TriathlonApp extends StatelessWidget {
  const TriathlonApp({
    super.key,
    required this.clientSupabase,
    required this.athleteController,
    required this.connecterUtilisateur,
    required this.deconnecterUtilisateur,
    required this.inscrireAthlete,
  });

  final SupabaseClient clientSupabase;
  final AthleteController athleteController;
  final ConnecterUtilisateur connecterUtilisateur;
  final DeconnecterUtilisateur deconnecterUtilisateur;
  final InscrireAthlete inscrireAthlete;

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
        connecterUtilisateur: connecterUtilisateur,
        deconnecterUtilisateur: deconnecterUtilisateur,
        inscrireAthlete: inscrireAthlete,
      ),
    );
  }
}
