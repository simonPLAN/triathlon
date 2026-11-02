import 'dart:async';

import 'package:triathlon/application/use_cases/competition/lister_competitions_ouvertes.dart';
import 'package:triathlon/application/use_cases/competition/suivre_competitions_athlete.dart';
import 'package:triathlon/application/use_cases/deconnecter_utilisateur.dart';
import 'package:triathlon/domain/ports/competition_repository.dart';
import 'package:triathlon/domain/ports/suivi_athlete_repository.dart';
import 'package:triathlon/domain/ports/auth_repository.dart';
import 'package:triathlon/domain/entities/profil_utilisateur.dart';
import 'package:triathlon/domain/entities/role_utilisateur.dart';
import 'package:triathlon/presentation/controllers/competitions_ouvertes_controller.dart';
import 'package:triathlon/presentation/pages/athlete/athlete_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/inscription/obtenir_inscription_utilisateur_connecte.dart';
import 'package:triathlon/application/use_cases/inscription/lister_inscriptions.dart';
import 'package:triathlon/application/use_cases/inscription/inscrire_athlete_competition.dart';
import 'package:triathlon/application/use_cases/inscription/modifier_dossard_inscription.dart';
import 'package:triathlon/application/use_cases/inscription/desinscrire_athlete_competition.dart';
import 'package:triathlon/application/use_cases/inscription/inscrire_utilisateur_connecte.dart';
import 'package:triathlon/application/use_cases/inscription/inscrire_invite.dart';
import 'package:triathlon/domain/entities/athlete.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/inscription.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';
import 'package:triathlon/domain/ports/inscription_repository.dart';
import 'package:triathlon/domain/ports/invite_repository.dart';
import 'package:triathlon/presentation/controllers/inscription_controller.dart';
import 'package:triathlon/presentation/controllers/suivi_inscription_utilisateur.dart';
import 'package:triathlon/presentation/models/etat_inscription_utilisateur.dart';
import 'package:triathlon/presentation/widgets/athlete/section_inscription_athlete.dart';

Competition competition([
  String id = 'competition',
  StatutCompetition statut = StatutCompetition.ouverte,
]) => Competition(
  id: id,
  nom: 'Triathlon',
  dateCompetition: DateTime(2026),
  coachId: 'coach',
  statut: statut,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
  demarrageAutomatiqueMancheSuivante: false,
);
Inscription inscription([int? dossard]) => Inscription(
  id: 'inscription',
  competitionId: 'competition',
  athlete: const Athlete(id: 'athlete', prenom: 'Alex', nom: 'Martin'),
  numeroDossard: dossard,
  dateInscription: DateTime(2026),
);

class DepotInscriptions extends Fake implements InscriptionRepository {
  final Set<String> erreurs = {};
  Inscription? actuelle;
  Completer<Inscription?>? attente;
  int lectures = 0;
  int desinscriptions = 0;
  @override
  Future<Inscription?> obtenirInscriptionUtilisateurConnecte({
    required String competitionId,
  }) async {
    lectures++;
    if (erreurs.contains(competitionId)) throw Exception('Réseau indisponible');
    if (attente != null) return attente!.future;
    return actuelle;
  }

  @override
  Future<Inscription> inscrireUtilisateurConnecte({
    required String competitionId,
  }) async => actuelle = inscription();
  @override
  Future<Inscription> modifierNumeroDossard({
    required String inscriptionId,
    int? numeroDossard,
  }) async => actuelle = inscription(numeroDossard);
  @override
  Future<void> desinscrire(String id) async {
    desinscriptions++;
    actuelle = null;
  }
}

class DepotInvites extends Fake implements InviteRepository {}

InscriptionController controller(DepotInscriptions depot) =>
    InscriptionController(
      ListerInscriptions(depot),
      InscrireAthleteCompetition(depot),
      ModifierDossardInscription(depot),
      DesinscrireAthleteCompetition(depot),
      InscrireUtilisateurConnecte(depot),
      ObtenirInscriptionUtilisateurConnecte(depot),
      InscrireInvite(DepotInvites()),
    );

class DepotCompetitions extends Fake implements CompetitionRepository {
  bool erreur = false;
  @override
  Future<List<Competition>> obtenirOuvertes() async {
    if (erreur) throw Exception('Réseau indisponible');
    return [competition()];
  }
}

class DepotSuivi extends Fake implements SuiviAthleteRepository {
  DepotSuivi(this.inscriptions);
  final DepotInscriptions inscriptions;
  bool erreur = false;
  @override
  Future<List<Competition>> obtenirCompetitionsInscrites() async {
    if (erreur) throw Exception('Réseau indisponible');
    return inscriptions.actuelle == null ? [] : [competition()];
  }
}

class AuthFake extends Fake implements AuthRepository {}

Future<void> afficherDashboard(
  WidgetTester tester,
  InscriptionController inscriptions,
  CompetitionsOuvertesController competitions,
) => tester.pumpWidget(
  MaterialApp(
    home: AthleteDashboardPage(
      profil: const ProfilUtilisateur(
        id: 'athlete',
        prenom: 'Alex',
        nom: 'Martin',
        role: RoleUtilisateur.athlete,
      ),
      inscriptionController: inscriptions,
      competitionsController: competitions,
      deconnecterUtilisateur: DeconnecterUtilisateur(AuthFake()),
    ),
  ),
);

void main() {
  test(
    'erreur par compétition, reprise indépendante et absence confirmée',
    () async {
      final depot = DepotInscriptions()..erreurs.add('competition');
      final suivi = SuiviInscriptionUtilisateur(
        ObtenirInscriptionUtilisateurConnecte(depot),
      );
      addTearDown(suivi.dispose);
      expect(
        suivi.pour('competition').statut,
        StatutVerificationInscription.nonVerifiee,
      );
      await Future.wait([
        suivi.verifier(competition()),
        suivi.verifier(competition('autre')),
      ]);
      expect(
        suivi.pour('competition').statut,
        StatutVerificationInscription.erreur,
      );
      expect(
        suivi.pour('autre').statut,
        StatutVerificationInscription.verifiee,
      );
      depot.erreurs.clear();
      await suivi.verifier(competition());
      expect(
        suivi.pour('competition').statut,
        StatutVerificationInscription.verifiee,
      );
      expect(suivi.pour('competition').inscription, isNull);
      expect(suivi.pour('competition').erreur, isNull);
    },
  );

  test('une réponse ancienne ne remplace pas une inscription ou un dossard confirmé', () async {
    final depot = DepotInscriptions()..attente = Completer<Inscription?>();
    final suivi = SuiviInscriptionUtilisateur(
      ObtenirInscriptionUtilisateurConnecte(depot),
    );
    addTearDown(suivi.dispose);
    final requete = suivi.verifier(competition());
    await Future<void>.delayed(Duration.zero);
    expect(
      suivi.pour('competition').statut,
      StatutVerificationInscription.enCours,
    );
    suivi.enregistrer('competition', inscription(42));
    depot.attente!.complete(null);
    await requete;
    expect(suivi.pour('competition').inscription?.numeroDossard, 42);
  });

  test('réinitialisation invalide les lectures encore en cours', () async {
    final depot = DepotInscriptions()..attente = Completer<Inscription?>();
    final suivi = SuiviInscriptionUtilisateur(
      ObtenirInscriptionUtilisateurConnecte(depot),
    );
    final requete = suivi.verifier(competition());
    await Future<void>.delayed(Duration.zero);
    suivi.reinitialiser();
    depot.attente!.complete(inscription());
    await requete;
    expect(
      suivi.pour('competition').statut,
      StatutVerificationInscription.nonVerifiee,
    );
    suivi.dispose();
  });

  test('les vérifications simultanées partagent la même requête', () async {
    final depot = DepotInscriptions()..attente = Completer<Inscription?>();
    final suivi = SuiviInscriptionUtilisateur(
      ObtenirInscriptionUtilisateurConnecte(depot),
    );
    final premiere = suivi.verifier(competition());
    final seconde = suivi.verifier(competition());
    await Future<void>.delayed(Duration.zero);
    expect(depot.lectures, 1);
    depot.attente!.complete(null);
    await Future.wait([premiere, seconde]);
    suivi.dispose();
  });

  test('inscription, attribution puis retrait du dossard, désinscription restent vérifiés', () async {
    final depot = DepotInscriptions();
    final c = controller(depot);
    addTearDown(c.dispose);
    await c.inscrireUtilisateurConnecte(competition: competition());
    expect(c.estInscritA('competition'), isTrue);
    await c.modifierDossard(inscription: depot.actuelle!, numeroDossard: 12);
    expect(c.inscriptionUtilisateurPour('competition')!.numeroDossard, 12);
    await c.modifierDossard(inscription: depot.actuelle!, numeroDossard: null);
    expect(c.inscriptionUtilisateurPour('competition')!.numeroDossard, isNull);
    await c.desinscrire(depot.actuelle!, competition: competition());
    expect(c.inscriptionUtilisateurVerifiee('competition'), isTrue);
    expect(c.estInscritA('competition'), isFalse);
    expect(c.verificationEnCoursPour('competition'), isFalse);
  });

  test(
    'la désinscription athlète est refusée quand la compétition a commencé',
    () async {
      final depot = DepotInscriptions()..actuelle = inscription();
      final c = controller(depot);
      addTearDown(c.dispose);
      final succes = await c.desinscrire(
        inscription(),
        competition: competition('competition', StatutCompetition.enCours),
      );
      expect(succes, isFalse);
      expect(depot.desinscriptions, 0);
      expect(c.erreur, contains('fermées'));
    },
  );

  testWidgets(
    'erreur de lecture ne reste pas sur le chargement et propose une reprise',
    (tester) async {
      final depot = DepotInscriptions()..erreurs.add('competition');
      final suivi = SuiviInscriptionUtilisateur(
        ObtenirInscriptionUtilisateurConnecte(depot),
      );
      await suivi.verifier(competition());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: suivi,
              builder: (_, _) => SectionInscriptionAthlete(
                competition: competition(),
                etat: suivi.pour('competition'),
                inscriptionEnCours: false,
                desinscriptionEnCours: false,
                onReessayer: () => suivi.verifier(competition()),
                onInscrire: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Réessayer la vérification'), findsOneWidget);
      expect(find.text('Non inscrit'), findsNothing);
      depot.erreurs.clear();
      await tester.tap(find.text('Réessayer la vérification'));
      await tester.pumpAndSettle();
      expect(find.text('Non inscrit'), findsOneWidget);
      expect(find.text('S’inscrire'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      suivi.dispose();
    },
  );

  testWidgets('une requête qui ne répond pas devient une erreur avec reprise', (
    tester,
  ) async {
    final depot = DepotInscriptions()..attente = Completer<Inscription?>();
    final suivi = SuiviInscriptionUtilisateur(
      ObtenirInscriptionUtilisateurConnecte(depot),
      delaiVerification: const Duration(seconds: 2),
    );
    final requete = suivi.verifier(competition());
    await tester.pump();
    expect(
      suivi.pour('competition').statut,
      StatutVerificationInscription.enCours,
    );
    await tester.pump(const Duration(seconds: 3));
    await requete;
    expect(
      suivi.pour('competition').statut,
      StatutVerificationInscription.erreur,
    );
    depot.attente!.complete(null);
    suivi.dispose();
  });

  testWidgets(
    'dashboard : inscription, actualisation du dossard puis désinscription',
    (tester) async {
      final depot = DepotInscriptions();
      final c = controller(depot);
      final competitions = CompetitionsOuvertesController(
        ListerCompetitionsOuvertes(DepotCompetitions()),
        SuivreCompetitionsAthlete(DepotSuivi(depot)),
      );
      await afficherDashboard(tester, c, competitions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inscriptions ouvertes'));
      await tester.pumpAndSettle();
      expect(find.text('Non inscrit'), findsOneWidget);
      await tester.ensureVisible(find.text('S’inscrire'));
      await tester.tap(find.text('S’inscrire'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('S’inscrire').last);
      await tester.pumpAndSettle();
      expect(find.text('Inscrit'), findsOneWidget);
      depot.actuelle = inscription(77);
      await tester.tap(find.byTooltip('Actualiser'));
      await tester.pumpAndSettle();
      expect(find.text('Dossard n°77'), findsOneWidget);
      await tester.ensureVisible(find.text('Se désinscrire'));
      await tester.tap(find.text('Se désinscrire'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Se désinscrire').last);
      await tester.pumpAndSettle();
      expect(find.text('Non inscrit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Mes compétitions'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tu n’es inscrit à aucune compétition.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      competitions.dispose();
    },
  );

  testWidgets(
    'une actualisation échouée après succès conserve l’inscription confirmée',
    (tester) async {
      final depot = DepotInscriptions();
      final c = controller(depot);
      final repoCompetitions = DepotCompetitions();
      final suivi = DepotSuivi(depot);
      final competitions = CompetitionsOuvertesController(
        ListerCompetitionsOuvertes(repoCompetitions),
        SuivreCompetitionsAthlete(suivi),
      );
      await afficherDashboard(tester, c, competitions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inscriptions ouvertes'));
      await tester.pumpAndSettle();
      repoCompetitions.erreur = true;
      suivi.erreur = true;
      await tester.ensureVisible(find.text('S’inscrire'));
      await tester.tap(find.text('S’inscrire'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('S’inscrire').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mes compétitions'));
      await tester.pumpAndSettle();
      expect(find.text('Inscrit'), findsOneWidget);
      expect(find.textContaining('Actualisation impossible'), findsOneWidget);
      expect(c.inscriptionUtilisateurVerifiee('competition'), isTrue);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      competitions.dispose();
    },
  );

  for (final statut in [
    StatutCompetition.brouillon,
    StatutCompetition.enCours,
    StatutCompetition.terminee,
    StatutCompetition.annulee,
  ]) {
    testWidgets(
      'inscription connue et fermeture expliquée pour ${statut.name}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SectionInscriptionAthlete(
                competition: competition('competition', statut),
                etat: EtatInscriptionUtilisateur(
                  statut: StatutVerificationInscription.verifiee,
                  inscription: inscription(12),
                ),
                inscriptionEnCours: false,
                desinscriptionEnCours: false,
                onReessayer: () {},
                onInscrire: () {},
                onDesinscrire: () {},
              ),
            ),
          ),
        );
        expect(find.text('Inscrit'), findsOneWidget);
        expect(find.text('Dossard n°12'), findsOneWidget);
        expect(find.text('Inscriptions fermées'), findsOneWidget);
        expect(find.text('S’inscrire'), findsNothing);
        expect(find.text('Se désinscrire'), findsNothing);
        expect(
          find.textContaining(
            statut == StatutCompetition.brouillon
                ? 'préparation'
                : statut == StatutCompetition.enCours
                ? 'commencé'
                : statut == StatutCompetition.terminee
                ? 'terminée'
                : 'annulée',
          ),
          findsOneWidget,
        );
      },
    );
  }
}
