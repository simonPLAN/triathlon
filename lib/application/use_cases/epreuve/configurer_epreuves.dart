import '../../../domain/entities/epreuve.dart';
import '../../../domain/ports/epreuve_repository.dart';
import '../../../domain/ports/manche_repository.dart';
import '../../../domain/services/validation_epreuve.dart';
import 'verifier_competition_brouillon.dart';

class ConfigurerEpreuves {
  ConfigurerEpreuves(this._epreuves, this._manches, this._verifierCompetition);
  final EpreuveRepository _epreuves;
  final MancheRepository _manches;
  final VerifierCompetitionBrouillon _verifierCompetition;

  Future<void> _verifier(Epreuve epreuve) async {
    await _verifierCompetition.executer(epreuve.competitionId);
    final actuelle = await _epreuves.obtenirParId(epreuve.id);
    if (actuelle == null || actuelle.competitionId != epreuve.competitionId) {
      throw StateError('Cette épreuve est introuvable dans la compétition.');
    }
    final manches = await _manches.obtenirParEpreuve(epreuve.id);
    if (manches.any(
      (m) =>
          !m.estAVenir ||
          m.heureDepart != null ||
          m.heurePremiereArrivee != null ||
          m.resultatsPublies,
    )) {
      throw StateError(
        'Une manche a déjà démarré : cette épreuve est verrouillée.',
      );
    }
  }

  Future<Epreuve> modifier(Epreuve epreuve) async {
    ValidationEpreuve.verifier(epreuve);
    await _verifier(epreuve);
    return _epreuves.modifier(
      epreuve.copierAvec(
        nom: epreuve.nom.trim(),
        dateModification: DateTime.now(),
      ),
    );
  }

  Future<void> supprimer(Epreuve epreuve) async {
    await _verifier(epreuve);
    await _epreuves.supprimer(epreuve.id);
  }

  Future<void> reordonner(String competitionId, List<String> ids) async {
    await _verifierCompetition.executer(competitionId);
    final epreuves = await _epreuves.obtenirParCompetition(competitionId);
    if (ids.length != epreuves.length ||
        ids.toSet().length != ids.length ||
        !ids.toSet().containsAll(epreuves.map((e) => e.id))) {
      throw ArgumentError(
        'L’ordre doit contenir chaque épreuve exactement une fois.',
      );
    }
    for (final epreuve in epreuves) {
      await _verifier(epreuve);
    }
    await _epreuves.reordonner(competitionId, ids);
  }
}
