import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/inscription/inscrire_invite.dart';
import 'package:triathlon/domain/entities/athlete.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/inscription.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';
import 'package:triathlon/domain/ports/invite_repository.dart';

Competition competition(StatutCompetition statut) => Competition(
  id: 'competition',
  nom: 'Triathlon',
  dateCompetition: DateTime(2026),
  coachId: 'coach',
  statut: statut,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
  demarrageAutomatiqueMancheSuivante: false,
);

class FakeInviteRepository implements InviteRepository {
  int appels = 0;
  @override
  Future<Inscription> inscrire({
    required String competitionId,
    required String prenom,
    required String nom,
    int? numeroDossard,
  }) async {
    appels++;
    return Inscription(
      id: 'inscription',
      competitionId: competitionId,
      athlete: Athlete(id: 'invite', prenom: prenom, nom: nom),
      numeroDossard: numeroDossard,
      dateInscription: DateTime(2026),
    );
  }
}

void main() {
  test('inscrit un invité sans compte et normalise son nom', () async {
    final repo = FakeInviteRepository();
    final inscription = await InscrireInvite(repo).executer(
      competition: competition(StatutCompetition.brouillon),
      prenom: ' Julie ',
      nom: ' Martin ',
      numeroDossard: 42,
    );
    expect(inscription.athlete.nomComplet, 'Julie Martin');
    expect(inscription.numeroDossard, 42);
    expect(repo.appels, 1);
  });

  test('refuse une compétition démarrée sans appeler le dépôt', () {
    final repo = FakeInviteRepository();
    expect(
      () => InscrireInvite(repo).executer(
        competition: competition(StatutCompetition.enCours),
        prenom: 'Julie',
        nom: 'Martin',
      ),
      throwsStateError,
    );
    expect(repo.appels, 0);
  });

  test('refuse un nom vide et un dossard invalide', () {
    final repo = FakeInviteRepository();
    final useCase = InscrireInvite(repo);
    expect(
      () => useCase.executer(
        competition: competition(StatutCompetition.ouverte),
        prenom: ' ',
        nom: 'Martin',
      ),
      throwsArgumentError,
    );
    expect(
      () => useCase.executer(
        competition: competition(StatutCompetition.ouverte),
        prenom: 'Julie',
        nom: 'Martin',
        numeroDossard: 0,
      ),
      throwsArgumentError,
    );
    expect(repo.appels, 0);
  });
}
