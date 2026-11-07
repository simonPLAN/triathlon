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
    required String pseudo,
    int? numeroDossard,
  }) async {
    appels++;
    return Inscription(
      id: 'inscription',
      competitionId: competitionId,
      athlete: Athlete(id: 'invite', pseudo: pseudo),
      numeroDossard: numeroDossard,
      dateInscription: DateTime(2026),
    );
  }
}

void main() {
  test('inscrit un invité avec un pseudo normalisé', () async {
    final repo = FakeInviteRepository();
    final inscription = await InscrireInvite(repo).executer(
      competition: competition(StatutCompetition.brouillon),
      pseudo: ' Julie_42 ',
      numeroDossard: 42,
    );
    expect(inscription.athlete.pseudo, 'Julie_42');
    expect(inscription.numeroDossard, 42);
    expect(repo.appels, 1);
  });

  test('refuse une compétition démarrée sans appeler le dépôt', () {
    final repo = FakeInviteRepository();
    expect(
      () => InscrireInvite(repo).executer(
        competition: competition(StatutCompetition.enCours),
        pseudo: 'Julie_42',
      ),
      throwsStateError,
    );
    expect(repo.appels, 0);
  });

  test('refuse un pseudo invalide et un dossard invalide', () {
    final repo = FakeInviteRepository();
    final useCase = InscrireInvite(repo);
    expect(
      () => useCase.executer(
        competition: competition(StatutCompetition.ouverte),
        pseudo: ' ',
      ),
      throwsArgumentError,
    );
    expect(
      () => useCase.executer(
        competition: competition(StatutCompetition.ouverte),
        pseudo: 'Julie_42',
        numeroDossard: 0,
      ),
      throwsArgumentError,
    );
    expect(repo.appels, 0);
  });
}
