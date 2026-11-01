import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/connecter_utilisateur.dart';
import '../../application/use_cases/deconnecter_utilisateur.dart';
import '../../application/use_cases/inscrire_athlete.dart';
import '../controllers/athlete_controller.dart';
import 'athletes_page.dart';
import 'connexion_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
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
  State<AuthGate> createState() {
    return _AuthGateState();
  }
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _abonnementAuth;

  @override
  void initState() {
    super.initState();

    _abonnementAuth = widget.clientSupabase.auth.onAuthStateChange.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _abonnementAuth?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.clientSupabase.auth.currentSession;

    if (session == null) {
      return ConnexionPage(
        connecterUtilisateur: widget.connecterUtilisateur,
        inscrireAthlete: widget.inscrireAthlete,
      );
    }

    return AthletesPage(
      key: ValueKey(session.user.id),
      controller: widget.athleteController,
      inscrireAthlete: widget.inscrireAthlete,
      deconnecterUtilisateur: widget.deconnecterUtilisateur,
    );
  }
}
