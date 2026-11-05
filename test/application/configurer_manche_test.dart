import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/manche/configurer_manche.dart';
import 'package:triathlon/domain/entities/manche.dart';
import 'package:triathlon/domain/entities/statut_manche.dart';
import 'package:triathlon/domain/ports/configuration_manche_repository.dart';

Manche manche({StatutManche statut = StatutManche.aVenir}) => Manche(
  id: 'm', epreuveId: 'e', numero: 1, statut: statut, resultatsPublies: false,
  dateCreation: DateTime(2026), dateModification: DateTime(2026));

class DepotConfiguration implements ConfigurationMancheRepository {
  List<String>? recus;
  @override
  Future<Manche> configurer({required String mancheId, required List<String> athleteIds,
    required int dureeLimiteSecondes}) async {
    recus = athleteIds;
    return manche().copierAvec(participantsDefinis: true,
      participantsAthleteIds: athleteIds, dureeLimiteSecondes: dureeLimiteSecondes);
  }
}

void main() {
  test('conserve la sélection ordonnée et le délai propre à la manche', () async {
    final depot = DepotConfiguration();
    final resultat = await ConfigurerManche(depot).executer(manche: manche(),
      athleteIds: ['b','a'], dureeLimiteSecondes: 60);
    expect(depot.recus, ['b','a']);
    expect(resultat.dureeLimiteSecondes, 60);
    expect(resultat.contientParticipant('c'), isFalse);
    expect(resultat.contientParticipant('a'), isTrue);
  });
  test('refuse une sélection vide, les doublons et un délai invalide', () async {
    final useCase = ConfigurerManche(DepotConfiguration());
    for (final selection in <List<String>>[[], ['a','a'], ['']]) {
      expect(() => useCase.executer(manche: manche(), athleteIds: selection,
        dureeLimiteSecondes: 60), throwsArgumentError);
    }
    expect(() => useCase.executer(manche: manche(), athleteIds: ['a'],
      dureeLimiteSecondes: 0), throwsArgumentError);
  });
  test('fige configuration et sélection après le départ', () {
    expect(() => ConfigurerManche(DepotConfiguration()).executer(
      manche: manche(statut: StatutManche.enCours), athleteIds: ['a'],
      dureeLimiteSecondes: 60), throwsStateError);
  });
}
