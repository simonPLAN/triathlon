import 'package:flutter/foundation.dart';

import '../../application/use_cases/resultat/consulter_resultats_competition.dart';
import '../../domain/entities/epreuve.dart';
import '../../domain/entities/resultats_competition.dart';
import '../../domain/entities/resultat_publie.dart';
import '../../domain/services/calcul_classement_global.dart';
import 'epreuve_controller.dart';
import 'manche_controller.dart';
import 'resultat_controller.dart';

typedef DashboardResultatLine = LigneResultatsCompetition;

class DashboardResultatsController extends ChangeNotifier {
  DashboardResultatsController(
    this._epreuveController,
    this._mancheController,
    this._resultatController, {
    this.consulter,
  });
  final EpreuveController _epreuveController;
  final MancheController _mancheController;
  final ResultatController _resultatController;
  final ConsulterResultatsCompetition? consulter;
  bool _chargement = false, _dispose = false;
  String? _erreur, _filtreEpreuveId;
  List<DashboardResultatLine> _lignes = const [];
  List<Epreuve> _epreuves = const [];
  bool get chargement => _chargement;
  String? get erreur => _erreur;
  String? get filtreEpreuveId => _filtreEpreuveId;
  List<Epreuve> get epreuves => List.unmodifiable(_epreuves);
  List<DashboardResultatLine> get lignes => List.unmodifiable(
    _lignes.where(
      (l) => _filtreEpreuveId == null || l.epreuve.id == _filtreEpreuveId,
    ),
  );

  List<DashboardAthleteStanding> get classement =>
      const CalculClassementGlobal()
          .calculer(
            lignes.map(
              (l) => ResultatPublie(
                athleteId: l.resultat.athlete.id,
                nomAthlete: l.resultat.athlete.nomComplet,
                epreuveId: l.epreuve.id,
                nomEpreuve: l.epreuve.nom,
                mancheId: l.manche.id,
                numeroManche: l.manche.numero,
                position: l.resultat.position,
                points: l.resultat.points,
                statut: l.resultat.statut.name,
                tempsMillisecondes: l.resultat.tempsTotalMillisecondes,
              ),
            ),
          )
          .map(
            (s) => DashboardAthleteStanding(
              athleteId: s.athleteId,
              nom: s.nom,
              points: s.points,
              manches: s.nombreManches,
              rang: s.rang,
            ),
          )
          .toList(growable: false);

  Future<void> charger(String competitionId) async {
    if (_chargement || _dispose) return;
    _chargement = true;
    _erreur = null;
    notifyListeners();
    try {
      final lecture =
          consulter ?? _epreuveController.consulterResultatsCompetition;
      final ResultatsCompetition donnees;
      if (lecture != null) {
        donnees = await lecture
            .executer(competitionId)
            .timeout(const Duration(seconds: 30));
      } else {
        // Compatibilité avec les anciennes compositions/tests. L'application
        // principale injecte toujours la lecture indépendante via les ports.
        donnees = await _chargerAncienneComposition(competitionId);
      }
      if (_dispose) return;
      _epreuves = donnees.epreuves;
      _lignes = donnees.lignes;
      if (!_epreuves.any((e) => e.id == _filtreEpreuveId)) {
        _filtreEpreuveId = null;
      }
    } catch (_) {
      if (!_dispose) {
        _erreur = 'Impossible de charger tous les résultats. Vérifie ta connexion puis réessaie.';
      }
    } finally {
      if (!_dispose) {
        _chargement = false;
        notifyListeners();
      }
    }
  }

  Future<ResultatsCompetition> _chargerAncienneComposition(String id) async {
    await _epreuveController.charger(id);
    if (_epreuveController.erreur != null) {
      throw StateError('Épreuves indisponibles.');
    }
    final epreuves = List<Epreuve>.of(_epreuveController.epreuves);
    final lignes = <DashboardResultatLine>[];
    for (final epreuve in epreuves) {
      await _mancheController.charger(epreuve.id);
      if (_mancheController.erreur != null) {
        throw StateError('Manches indisponibles.');
      }
      for (final manche in List.of(_mancheController.manches)) {
        await _resultatController.charger(manche.id);
        if (_resultatController.erreur != null) {
          throw StateError('Résultats indisponibles.');
        }
        lignes.addAll(
          _resultatController.resultats.map(
            (r) => LigneResultatsCompetition(
              epreuve: epreuve,
              manche: manche,
              resultat: r,
            ),
          ),
        );
      }
    }
    return ResultatsCompetition(epreuves: epreuves, lignes: lignes);
  }

  void filtrerParEpreuve(String? id) {
    _filtreEpreuveId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _dispose = true;
    super.dispose();
  }
}

class DashboardAthleteStanding {
  const DashboardAthleteStanding({
    required this.athleteId,
    required this.nom,
    required this.points,
    required this.manches,
    this.rang = 0,
  });
  final String athleteId, nom;
  final int points, manches, rang;
}
