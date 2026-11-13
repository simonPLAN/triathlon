import '../../../domain/entities/affiche_epreuve.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/fichier_affiche_epreuve.dart';
import '../../../domain/ports/affiche_epreuve_repository.dart';
import '../../../domain/ports/epreuve_repository.dart';
import '../../../domain/services/validation_affiche_epreuve.dart';
import 'verifier_competition_brouillon.dart';

class GererAffichesEpreuve {
  GererAffichesEpreuve(
    this._affiches,
    this._epreuves,
    this._verifierCompetition,
  );

  final AfficheEpreuveRepository _affiches;
  final EpreuveRepository _epreuves;
  final VerifierCompetitionBrouillon _verifierCompetition;

  Future<List<AfficheEpreuve>> lister(String epreuveId) async {
    final id = _verifierIdentifiant(epreuveId, 'L’épreuve');
    final affiches = await _affiches.obtenirParEpreuve(id);
    return _trierEtVerifier(affiches, id);
  }

  Future<Uri> obtenirUrlConsultation(AfficheEpreuve affiche) {
    final id = _verifierIdentifiant(affiche.id, 'L’affiche');
    return _affiches.obtenirUrlConsultation(id);
  }

  Future<AfficheEpreuve> ajouter({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    final epreuve = await _obtenirEpreuveModifiable(epreuveId);
    final actuelles = await lister(epreuve.id);
    if (actuelles.length >= ValidationAfficheEpreuve.nombreMaximum) {
      throw StateError('Deux affiches maximum sont autorisées par épreuve.');
    }
    ValidationAfficheEpreuve.verifierPosition(
      position,
      nombreActuel: actuelles.length,
    );
    if (position != actuelles.length + 1) {
      throw ArgumentError(
        'Ajoute la nouvelle affiche à la suite, puis réorganise la galerie.',
      );
    }
    ValidationAfficheEpreuve.verifierFichier(fichier);
    final texte = ValidationAfficheEpreuve.normaliserTexteAlternatif(
      texteAlternatif,
    );
    return _affiches.ajouter(
      epreuveId: epreuve.id,
      position: position,
      texteAlternatif: texte,
      fichier: fichier,
    );
  }

  Future<AfficheEpreuve> remplacer({
    required AfficheEpreuve affiche,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    final epreuve = await _obtenirEpreuveModifiable(affiche.epreuveId);
    await _verifierAffichePresente(affiche, epreuve.id);
    ValidationAfficheEpreuve.verifierFichier(fichier);
    final texte = ValidationAfficheEpreuve.normaliserTexteAlternatif(
      texteAlternatif,
    );
    return _affiches.remplacer(
      afficheId: affiche.id,
      epreuveId: epreuve.id,
      texteAlternatif: texte,
      fichier: fichier,
    );
  }

  Future<AfficheEpreuve> modifierTexteAlternatif({
    required AfficheEpreuve affiche,
    required String texteAlternatif,
  }) async {
    final epreuve = await _obtenirEpreuveModifiable(affiche.epreuveId);
    await _verifierAffichePresente(affiche, epreuve.id);
    final texte = ValidationAfficheEpreuve.normaliserTexteAlternatif(
      texteAlternatif,
    );
    return _affiches.modifierTexteAlternatif(
      afficheId: affiche.id,
      epreuveId: epreuve.id,
      texteAlternatif: texte,
    );
  }

  Future<List<AfficheEpreuve>> reordonner({
    required String epreuveId,
    required List<String> afficheIds,
  }) async {
    final epreuve = await _obtenirEpreuveModifiable(epreuveId);
    final actuelles = await lister(epreuve.id);
    final ids = afficheIds
        .map((id) => _verifierIdentifiant(id, 'L’affiche'))
        .toList(growable: false);
    if (ids.length != actuelles.length ||
        ids.toSet().length != ids.length ||
        !ids.toSet().containsAll(actuelles.map((a) => a.id))) {
      throw ArgumentError(
        'L’ordre doit contenir chaque affiche exactement une fois.',
      );
    }
    return _affiches.reordonner(epreuveId: epreuve.id, afficheIds: ids);
  }

  Future<List<AfficheEpreuve>> supprimer(AfficheEpreuve affiche) async {
    final epreuve = await _obtenirEpreuveModifiable(affiche.epreuveId);
    await _verifierAffichePresente(affiche, epreuve.id);
    return _affiches.supprimer(afficheId: affiche.id, epreuveId: epreuve.id);
  }

  Future<Epreuve> _obtenirEpreuveModifiable(String epreuveId) async {
    final id = _verifierIdentifiant(epreuveId, 'L’épreuve');
    final epreuve = await _epreuves.obtenirParId(id);
    if (epreuve == null) {
      throw StateError('Cette épreuve est introuvable.');
    }
    await _verifierCompetition.executer(epreuve.competitionId);
    return epreuve;
  }

  Future<void> _verifierAffichePresente(
    AfficheEpreuve affiche,
    String epreuveId,
  ) async {
    final id = _verifierIdentifiant(affiche.id, 'L’affiche');
    if (affiche.epreuveId != epreuveId) {
      throw StateError('Cette affiche n’appartient pas à l’épreuve.');
    }
    final actuelles = await lister(epreuveId);
    if (!actuelles.any((a) => a.id == id)) {
      throw StateError('Cette affiche est introuvable dans l’épreuve.');
    }
  }

  List<AfficheEpreuve> _trierEtVerifier(
    List<AfficheEpreuve> valeurs,
    String epreuveId,
  ) {
    if (valeurs.length > ValidationAfficheEpreuve.nombreMaximum ||
        valeurs.any((a) => a.epreuveId != epreuveId)) {
      throw StateError('Les affiches retournées sont incohérentes.');
    }
    final triees = [...valeurs]
      ..sort((a, b) => a.position.compareTo(b.position));
    for (var i = 0; i < triees.length; i++) {
      if (triees[i].position != i + 1) {
        throw StateError('L’ordre des affiches est incohérent.');
      }
    }
    return List.unmodifiable(triees);
  }

  String _verifierIdentifiant(String valeur, String nom) {
    final id = valeur.trim();
    if (id.isEmpty) throw ArgumentError('$nom est obligatoire.');
    return id;
  }
}
