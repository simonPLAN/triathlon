import 'package:flutter/foundation.dart';

import '../../application/use_cases/inscription/obtenir_inscription_utilisateur_connecte.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/inscription.dart';
import '../models/etat_inscription_utilisateur.dart';

/// État de lecture par compétition, indépendant des opérations du coach.
class SuiviInscriptionUtilisateur extends ChangeNotifier {
  SuiviInscriptionUtilisateur(
    this._obtenir, {
    this.delaiVerification = const Duration(seconds: 20),
  });
  final Duration delaiVerification;
  final ObtenirInscriptionUtilisateurConnecte _obtenir;
  final Map<String, EtatInscriptionUtilisateur> _etats = {};
  final Map<String, Future<void>> _requetes = {};
  final Map<String, Object> _versions = {};
  bool _detruit = false;

  EtatInscriptionUtilisateur pour(String id) =>
      _etats[id] ?? const EtatInscriptionUtilisateur();

  Future<void> verifier(Competition competition) {
    final id = competition.id;
    if (id.trim().isEmpty) return Future.value();
    final enCours = _requetes[id];
    if (enCours != null) return enCours;
    final version = Object();
    _versions[id] = version;
    // Installer la requête avant les notifications (un listener peut réessayer).
    final requete = Future<void>.microtask(
      () => _charger(competition, version),
    );
    _requetes[id] = requete;
    return requete;
  }

  Future<void> _charger(Competition competition, Object version) async {
    final id = competition.id;
    if (!_valide(id, version)) return;
    _etats[id] = EtatInscriptionUtilisateur(
      statut: StatutVerificationInscription.enCours,
      inscription: pour(id).inscription,
    );
    notifyListeners();
    try {
      final inscription = await _obtenir
          .executer(competition: competition)
          .timeout(delaiVerification);
      if (!_valide(id, version)) return;
      _etats[id] = EtatInscriptionUtilisateur(
        statut: StatutVerificationInscription.verifiee,
        inscription: inscription,
      );
    } catch (_) {
      if (!_valide(id, version)) return;
      _etats[id] = EtatInscriptionUtilisateur(
        statut: StatutVerificationInscription.erreur,
        inscription: pour(id).inscription,
        erreur: 'Impossible de vérifier ton inscription. Vérifie ta connexion puis réessaie.',
      );
    } finally {
      if (_valide(id, version)) {
        _requetes.remove(id);
        notifyListeners();
      }
    }
  }

  void enregistrer(String id, Inscription? inscription) {
    _versions[id] = Object();
    _requetes.remove(id);
    _etats[id] = EtatInscriptionUtilisateur(
      statut: StatutVerificationInscription.verifiee,
      inscription: inscription,
    );
    notifyListeners();
  }

  void actualiserSiConnue(Inscription inscription) {
    if (pour(inscription.competitionId).inscription?.id == inscription.id) {
      enregistrer(inscription.competitionId, inscription);
    }
  }

  void retirerSiConnue(Inscription inscription) {
    if (pour(inscription.competitionId).inscription?.id == inscription.id) {
      enregistrer(inscription.competitionId, null);
    }
  }

  void reinitialiser() {
    _versions.clear();
    _requetes.clear();
    _etats.clear();
    notifyListeners();
  }

  bool _valide(String id, Object version) =>
      !_detruit && identical(_versions[id], version);

  @override
  void dispose() {
    _detruit = true;
    _versions.clear();
    super.dispose();
  }
}
