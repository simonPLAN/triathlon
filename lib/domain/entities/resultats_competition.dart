import 'epreuve.dart';
import 'manche.dart';
import 'resultat.dart';

class LigneResultatsCompetition {
  const LigneResultatsCompetition({
    required this.epreuve,
    required this.manche,
    required this.resultat,
  });
  final Epreuve epreuve;
  final Manche manche;
  final Resultat resultat;
}

class ResultatsCompetition {
  ResultatsCompetition({
    required Iterable<Epreuve> epreuves,
    required Iterable<LigneResultatsCompetition> lignes,
  }) : epreuves = List.unmodifiable(epreuves),
       lignes = List.unmodifiable(lignes);
  final List<Epreuve> epreuves;
  final List<LigneResultatsCompetition> lignes;
}
