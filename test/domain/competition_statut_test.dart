import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';

Competition _competition(StatutCompetition statut) => Competition(
  id: 'competition-1',
  nom: 'Le Mans Triathlon',
  dateCompetition: DateTime(2026, 11, 17),
  coachId: 'coach-1',
  statut: statut,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
  demarrageAutomatiqueMancheSuivante: false,
);

void main() {
  test('une compétition ouverte peut revenir en brouillon', () {
    final resultat = _competition(StatutCompetition.ouverte)
        .repasserEnBrouillon();

    expect(resultat.statut, StatutCompetition.brouillon);
    expect(resultat.id, 'competition-1');
  });

  test('une compétition démarrée ne peut pas revenir en brouillon', () {
    expect(
      () => _competition(StatutCompetition.enCours).repasserEnBrouillon(),
      throwsStateError,
    );
  });
}
