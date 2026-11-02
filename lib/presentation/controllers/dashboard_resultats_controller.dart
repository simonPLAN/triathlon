import 'package:flutter/foundation.dart';

import '../../domain/entities/epreuve.dart';
import '../../domain/entities/manche.dart';
import '../../domain/entities/resultat.dart';
import 'epreuve_controller.dart';
import 'manche_controller.dart';
import 'resultat_controller.dart';

class DashboardResultatsController extends ChangeNotifier {
  DashboardResultatsController(
    this._epreuveController,
    this._mancheController,
    this._resultatController,
  );

  final EpreuveController _epreuveController;
  final MancheController _mancheController;
  final ResultatController _resultatController;

  bool _chargement = false;
  String? _erreur;
  String? _filtreEpreuveId;
  List<DashboardResultatLine> _lignes = const [];

  bool get chargement => _chargement;
  String? get erreur => _erreur;
  String? get filtreEpreuveId => _filtreEpreuveId;
  List<Epreuve> get epreuves => _epreuveController.epreuves;

  List<DashboardResultatLine> get lignes {
    if (_filtreEpreuveId == null) return List.unmodifiable(_lignes);
    return List.unmodifiable(
      _lignes.where((line) => line.epreuve.id == _filtreEpreuveId),
    );
  }

  List<DashboardAthleteStanding> get classement {
    final groupes = <String, DashboardAthleteStanding>{};
    for (final ligne in lignes) {
      final id = ligne.resultat.athlete.id;
      final actuel = groupes[id];
      groupes[id] = DashboardAthleteStanding(
        athleteId: id,
        nom: ligne.resultat.athlete.nomComplet,
        points: (actuel?.points ?? 0) + ligne.resultat.points,
        manches: (actuel?.manches ?? 0) + 1,
      );
    }
    final result = groupes.values.toList()
      ..sort((a, b) {
        final points = b.points.compareTo(a.points);
        return points != 0 ? points : a.nom.compareTo(b.nom);
      });
    return result;
  }

  Future<void> charger(String competitionId) async {
    if (_chargement) return;
    _chargement = true;
    _erreur = null;
    notifyListeners();
    try {
      await _epreuveController.charger(competitionId);
      final lignes = <DashboardResultatLine>[];
      for (final epreuve in _epreuveController.epreuves) {
        await _mancheController.charger(epreuve.id);
        for (final manche in _mancheController.manches) {
          await _resultatController.charger(manche.id);
          lignes.addAll(
            _resultatController.resultats.map(
              (resultat) => DashboardResultatLine(
                epreuve: epreuve,
                manche: manche,
                resultat: resultat,
              ),
            ),
          );
        }
      }
      _lignes = lignes;
    } catch (exception) {
      _erreur = exception.toString().replaceFirst('Exception: ', '');
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  void filtrerParEpreuve(String? epreuveId) {
    _filtreEpreuveId = epreuveId;
    notifyListeners();
  }
}

class DashboardResultatLine {
  const DashboardResultatLine({
    required this.epreuve,
    required this.manche,
    required this.resultat,
  });
  final Epreuve epreuve;
  final Manche manche;
  final Resultat resultat;
}

class DashboardAthleteStanding {
  const DashboardAthleteStanding({
    required this.athleteId,
    required this.nom,
    required this.points,
    required this.manches,
  });
  final String athleteId;
  final String nom;
  final int points;
  final int manches;
}
