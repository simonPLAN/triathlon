import '../../../domain/entities/resultats_competition.dart';
import '../../../domain/ports/epreuve_repository.dart';
import '../../../domain/ports/manche_repository.dart';
import '../../../domain/ports/resultat_repository.dart';

/// Lecture indépendante des états partagés des écrans épreuve/manche/arrivées.
/// Une erreur interrompt le chargement, plutôt que produire un total partiel.
class ConsulterResultatsCompetition {
  const ConsulterResultatsCompetition(
    this.epreuves,
    this.manches,
    this.resultats,
  );
  final EpreuveRepository epreuves;
  final MancheRepository manches;
  final ResultatRepository resultats;
  Future<ResultatsCompetition> executer(String competitionId) async {
    final epreuvesLues = await epreuves.obtenirParCompetition(competitionId);
    final lignes = <LigneResultatsCompetition>[];
    for (final epreuve in epreuvesLues) {
      for (final manche in await manches.obtenirParEpreuve(epreuve.id)) {
        for (final resultat in await resultats.obtenirParManche(manche.id)) {
          lignes.add(
            LigneResultatsCompetition(
              epreuve: epreuve,
              manche: manche,
              resultat: resultat,
            ),
          );
        }
      }
    }
    return ResultatsCompetition(epreuves: epreuvesLues, lignes: lignes);
  }
}
