import 'package:flutter/foundation.dart';

import '../../application/use_cases/ajouter_athlete.dart';
import '../../application/use_cases/lister_athletes.dart';
import '../../domain/entities/athlete.dart';

class AthleteController extends ChangeNotifier {
  AthleteController({
    required this._ajouterAthlete,
    required this._listerAthletes,
  });

  final AjouterAthlete _ajouterAthlete;
  final ListerAthletes _listerAthletes;

  List<Athlete> athletes = const [];
  bool chargement = false;
  String? erreur;

  int _version = 0;

  void reinitialiser() {
    _version++;
    athletes = const [];
    chargement = false;
    erreur = null;
    notifyListeners();
  }

  Future<void> charger() async {
    final version = ++_version;
    chargement = true;
    erreur = null;
    notifyListeners();

    try {
      final resultat = await _listerAthletes.executer();
      if (version == _version) athletes = resultat;
    } catch (_) {
      if (version == _version) erreur = 'Impossible de charger les athletes.';
    } finally {
      if (version == _version) {
        chargement = false;
        notifyListeners();
      }
    }
  }

  Future<bool> ajouter({required String prenom, required String nom}) async {
    erreur = null;
    try {
      await _ajouterAthlete.executer(prenom: prenom, nom: nom);
      await charger();
      return true;
    } on ArgumentError catch (exception) {
      erreur = exception.message?.toString() ?? 'Donnees invalides.';
      notifyListeners();
      return false;
    } catch (_) {
      erreur = "Impossible d'ajouter l'athlete.";
      notifyListeners();
      return false;
    }
  }
}
