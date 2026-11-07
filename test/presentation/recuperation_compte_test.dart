import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:triathlon/application/use_cases/auth/recuperer_compte.dart';
import 'package:triathlon/domain/ports/recuperation_compte_repository.dart';
import 'package:triathlon/domain/ports/source_liens_recuperation.dart';
import 'package:triathlon/domain/services/lien_recuperation.dart';
import 'package:triathlon/infrastructure/auth/configuration_authentification.dart';
import 'package:triathlon/infrastructure/repositories/supabase/recuperation_compte_repository_supabase.dart';
import 'package:triathlon/presentation/controllers/recuperation_compte_controller.dart';
import 'package:triathlon/presentation/navigation/recuperation_compte_host.dart';
import 'package:triathlon/presentation/pages/auth/mot_de_passe_oublie_page.dart';

final redirection = Uri.parse('triathlon://auth/reset-password');
final lien = Uri.parse('$redirection?code=valide');

class Depot implements RecuperationCompteRepository {
  String? email;
  String? motDePasse;
  int verifications = 0;
  int envois = 0;
  bool session = false;
  bool valide = false;
  bool erreur = false;
  Completer<void>? attente;
  @override
  Future<void> envoyerLien(String email, Uri redirection) async {
    envois++;
    this.email = email;
    await attente?.future;
  }

  @override
  Future<void> verifierLien(Uri lien) async {
    verifications++;
    if (erreur) {
      throw StateError(
        'Ce lien est expiré ou déjà utilisé. Demande un nouveau lien.',
      );
    }
    valide = true;
    session = true;
  }

  @override
  Future<void> changerMotDePasse(String motDePasse) async {
    if (!valide) throw StateError('Récupération non validée');
    this.motDePasse = motDePasse;
  }

  @override
  Future<void> terminer() async {
    if (valide) session = false;
    valide = false;
  }
}

class Source implements SourceLiensRecuperation {
  Source(this.initial);
  final Uri? initial;
  Future<void> Function(Uri)? reception;
  @override
  Future<void> demarrer(Future<void> Function(Uri) traiterLien) async {
    reception = traiterLien;
    if (initial != null) await traiterLien(initial!);
  }

  @override
  void dispose() {}
}

void main() {
  test('normalise email et refuse mots de passe invalides', () async {
    final depot = Depot();
    final useCase = RecupererCompte(depot, LienRecuperation(redirection));
    await useCase.envoyerLien(' sportif@example.fr ');
    expect(depot.email, 'sportif@example.fr');
    expect(() => useCase.envoyerLien('invalide'), throwsArgumentError);
    expect(
      () => useCase.changerMotDePasse('court', 'court'),
      throwsArgumentError,
    );
    expect(
      () => useCase.changerMotDePasse('motdepasse', 'different'),
      throwsArgumentError,
    );
    expect(depot.motDePasse, isNull);
  });

  test('ignore les liens étrangers et déduplique la réception', () async {
    final depot = Depot();
    final controller = RecuperationCompteController(
      RecupererCompte(depot, LienRecuperation(redirection)),
    );
    await controller.traiterLien(
      Uri.parse('triathlon-staging://auth/reset-password?code=test'),
    );
    expect(controller.active, isFalse);
    await controller.traiterLien(lien);
    await controller.traiterLien(lien);
    expect(depot.verifications, 1);
    await controller.enregistrer('motdepasse', 'motdepasse');
    expect(controller.etape, EtapeRecuperation.succes);
    await controller.fermer();
    expect(depot.session, isFalse);
    controller.dispose();
  });

  test(
    'le dépôt réel refuse un changement sans récupération validée',
    () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test',
      );
      final depot = RecuperationCompteRepositorySupabase(client);
      await expectLater(
        depot.changerMotDePasse('motdepasse'),
        throwsStateError,
      );
      await expectLater(
        depot.verifierLien(Uri.parse('$redirection#type=recovery')),
        throwsStateError,
      );
      await client.dispose();
    },
  );

  test('configuration staging exige un projet distinct explicite', () {
    expect(
      () => ConfigurationAuthentification(
        environnement: 'staging',
        urlSupabase: '',
        clePublique: '',
      ),
      throwsArgumentError,
    );
    final configuration = ConfigurationAuthentification(
      environnement: 'staging',
      urlSupabase: 'https://test.supabase.co',
      clePublique: 'public',
    );
    expect(configuration.redirection.scheme, 'triathlon-staging');
  });

  testWidgets('demande générique et protection contre double envoi', (
    tester,
  ) async {
    final depot = Depot()..attente = Completer<void>();
    final controller = RecuperationCompteController(
      RecupererCompte(depot, LienRecuperation(redirection)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MotDePasseOubliePage(
          controller: controller,
          emailInitial: 'sportif@example.fr',
        ),
      ),
    );
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pump();
    await tester.tap(find.text('Envoyer le lien'));
    expect(depot.envois, 1);
    depot.attente!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Si un compte existe'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  for (final session in [false, true]) {
    testWidgets(
      'lien initial ou reçu avec session=$session, formulaire et fermeture',
      (tester) async {
        final depot = Depot()..session = session;
        final controller = RecuperationCompteController(
          RecupererCompte(depot, LienRecuperation(redirection)),
        );
        final source = Source(session ? null : lien);
        final navigation = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          RecuperationCompteHost(
            controller: controller,
            sourceLiens: source,
            navigatorKey: navigation,
            child: MaterialApp(
              navigatorKey: navigation,
              home: Scaffold(
                body: Text(session ? 'Accueil connecté' : 'Connexion'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (session) {
          navigation.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Page secondaire')),
            ),
          );
          await tester.pumpAndSettle();
          await source.reception!(lien);
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey('nouveau-mot-de-passe')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('nouveau-mot-de-passe')),
          'motdepasse',
        );
        await tester.enterText(
          find.byKey(const ValueKey('confirmation-mot-de-passe')),
          'different',
        );
        await tester.tap(find.text('Enregistrer le nouveau mot de passe'));
        await tester.pumpAndSettle();
        expect(depot.motDePasse, isNull);
        await tester.enterText(
          find.byKey(const ValueKey('confirmation-mot-de-passe')),
          'motdepasse',
        );
        await tester.tap(find.text('Enregistrer le nouveau mot de passe'));
        await tester.pumpAndSettle();
        expect(depot.motDePasse, 'motdepasse');
        expect(find.text('Mot de passe modifié'), findsOneWidget);
        await tester.tap(find.text('Retour à la connexion'));
        await tester.pumpAndSettle();
        expect(controller.active, isFalse);
        expect(depot.session, isFalse);
        expect(find.text('Page secondaire'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      },
    );

    test(
      'lien expiré avec session=$session ne permet aucune modification',
      () async {
        final depot = Depot()
          ..session = session
          ..erreur = true;
        final controller = RecuperationCompteController(
          RecupererCompte(depot, LienRecuperation(redirection)),
        );
        await controller.traiterLien(lien);
        expect(controller.etape, EtapeRecuperation.erreur);
        expect(controller.erreur, contains('expiré'));
        await controller.enregistrer('motdepasse', 'motdepasse');
        expect(depot.motDePasse, isNull);
        await controller.fermer();
        expect(depot.session, session);
        controller.dispose();
      },
    );
  }
}
