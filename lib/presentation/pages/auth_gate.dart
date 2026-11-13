import 'dart:async';

import '../../application/use_cases/auth/supprimer_mon_compte.dart';
import 'compte/supprimer_compte_page.dart';

import '../controllers/recuperation_compte_controller.dart';
import '../controllers/confirmation_email_controller.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/connecter_utilisateur.dart';
import '../../application/use_cases/deconnecter_utilisateur.dart';
import '../../application/use_cases/inscrire_athlete.dart';
import '../../application/use_cases/obtenir_profil_connecte.dart';
import '../../domain/entities/profil_utilisateur.dart';
import '../../domain/ports/categorie_athlete_repository.dart';
import '../controllers/athlete_controller.dart';
import '../controllers/competition_controller.dart';
import '../controllers/competitions_ouvertes_controller.dart';
import '../controllers/epreuve_controller.dart';
import '../controllers/inscription_controller.dart';
import '../controllers/manche_controller.dart';
import '../controllers/resultat_controller.dart';
import 'athlete/athlete_dashboard_page.dart';
import 'athletes_page.dart';
import 'coach/coach_dashboard_page.dart';
import 'epreuve/epreuves_partagees_page.dart';
import 'competition/competitions_page.dart';
import 'connexion_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.clientSupabase,
    required this.athleteController,
    required this.competitionController,
    required this.connecterUtilisateur,
    required this.deconnecterUtilisateur,
    required this.inscrireAthlete,
    required this.obtenirProfilConnecte,
    required this.inscriptionController,
    required this.competitionsOuvertesController,
    required this.epreuveController,
    required this.mancheController,
    required this.resultatController,
    required this.recuperationCompte,
    required this.supprimerMonCompte,
    this.confirmationEmail,
    this.categoriesAthletes,
  });

  final CategorieAthleteRepository? categoriesAthletes;

  final ConfirmationEmailController? confirmationEmail;

  final SupabaseClient clientSupabase;
  final AthleteController athleteController;
  final ConnecterUtilisateur connecterUtilisateur;
  final DeconnecterUtilisateur deconnecterUtilisateur;
  final InscrireAthlete inscrireAthlete;
  final ObtenirProfilConnecte obtenirProfilConnecte;
  final CompetitionController competitionController;
  final InscriptionController inscriptionController;
  final CompetitionsOuvertesController competitionsOuvertesController;
  final EpreuveController epreuveController;
  final MancheController mancheController;
  final ResultatController resultatController;
  final RecuperationCompteController recuperationCompte;
  final SupprimerMonCompte supprimerMonCompte;

  @override
  State<AuthGate> createState() {
    return _AuthGateState();
  }
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _abonnementAuth;

  Future<ProfilUtilisateur>? _profilFuture;

  @override
  void initState() {
    super.initState();

    _preparerChargementProfil();

    _abonnementAuth = widget.clientSupabase.auth.onAuthStateChange.listen(
      (authState) {
        if (!mounted) {
          return;
        }

        setState(() {
          if (authState.session == null) {
            widget.athleteController.reinitialiser();
            widget.competitionController.reinitialiser();
            widget.competitionsOuvertesController.reinitialiser();
            widget.inscriptionController.reinitialiser();
            widget.epreuveController.reinitialiser();
            widget.mancheController.reinitialiser();
            widget.resultatController.reinitialiser();
            _profilFuture = null;
          } else {
            _profilFuture = widget.obtenirProfilConnecte.executer();
          }
        });
      },
      onError: (Object _) {
        // Les erreurs de récupération sont présentées par son contrôleur dédié.
      },
    );
  }

  void _preparerChargementProfil() {
    final session = widget.clientSupabase.auth.currentSession;

    if (session != null) {
      _profilFuture = widget.obtenirProfilConnecte.executer();
    }
  }

  Future<void> _rechargerProfil() async {
    setState(() {
      _profilFuture = widget.obtenirProfilConnecte.executer();
    });

    await _profilFuture;
  }

  void _ouvrirMonCompte() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            SupprimerComptePage(supprimerMonCompte: widget.supprimerMonCompte),
      ),
    );
  }

  void _ouvrirAthletes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AthletesPage(
            controller: widget.athleteController,
            inscrireAthlete: widget.inscrireAthlete,
            deconnecterUtilisateur: widget.deconnecterUtilisateur,
            groupes: widget.athleteController.groupes,
          );
        },
      ),
    );
  }

  void _ouvrirEpreuvesPartagees(BuildContext context) {
    final partages = widget.epreuveController.partages;
    if (partages == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EpreuvesPartageesPage(
          partages: partages,
          epreuveController: widget.epreuveController,
          mancheController: widget.mancheController,
          resultatController: widget.resultatController,
          inscriptionController: widget.inscriptionController,
        ),
      ),
    );
  }

  void _ouvrirCompetitions(
    BuildContext context,
    ProfilUtilisateur profilCoach,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return CompetitionsPage(
            controller: widget.competitionController,
            inscriptionController: widget.inscriptionController,
            profilCoach: profilCoach,
            epreuveController: widget.epreuveController,
            mancheController: widget.mancheController,
            resultatController: widget.resultatController,
          );
        },
      ),
    );
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
        recuperationCompte: widget.recuperationCompte,
        confirmationEmail: widget.confirmationEmail,
        connecterUtilisateur: widget.connecterUtilisateur,
        inscrireAthlete: widget.inscrireAthlete,
      );
    }

    final profilFuture = _profilFuture;

    if (profilFuture == null) {
      return const _PageChargementProfil();
    }

    return FutureBuilder<ProfilUtilisateur>(
      future: profilFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PageChargementProfil();
        }

        if (snapshot.hasError) {
          return _PageErreurProfil(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onReessayer: _rechargerProfil,
            onDeconnecter: widget.deconnecterUtilisateur.executer,
          );
        }

        final profil = snapshot.data;

        if (profil == null) {
          return _PageErreurProfil(
            message: 'Le profil utilisateur est introuvable.',
            onReessayer: _rechargerProfil,
            onDeconnecter: widget.deconnecterUtilisateur.executer,
          );
        }

        if (profil.estCoach) {
          return CoachDashboardPage(
            onMonCompte: _ouvrirMonCompte,
            profil: profil,
            deconnecterUtilisateur: widget.deconnecterUtilisateur,
            onVoirCompetitions: () {
              _ouvrirCompetitions(context, profil);
            },
            onVoirEpreuvesPartagees: () {
              _ouvrirEpreuvesPartagees(context);
            },
            onVoirAthletes: () {
              _ouvrirAthletes(context);
            },
          );
        }

        return AthleteDashboardPage(
          categoriesAthletes: widget.categoriesAthletes,
          onMonCompte: _ouvrirMonCompte,
          key: ValueKey(session.user.id),
          profil: profil,
          competitionsController: widget.competitionsOuvertesController,
          inscriptionController: widget.inscriptionController,
          deconnecterUtilisateur: widget.deconnecterUtilisateur,
          affichesController: widget.epreuveController.affiches,
        );
      },
    );
  }
}

class _PageChargementProfil extends StatelessWidget {
  const _PageChargementProfil();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du profil...'),
          ],
        ),
      ),
    );
  }
}

class _PageErreurProfil extends StatelessWidget {
  const _PageErreurProfil({
    required this.message,
    required this.onReessayer,
    required this.onDeconnecter,
  });

  final String message;
  final Future<void> Function() onReessayer;
  final Future<void> Function() onDeconnecter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur de profil'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: onDeconnecter,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onReessayer,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
