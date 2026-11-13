import 'package:flutter/foundation.dart';

import '../../application/use_cases/epreuve/gerer_affiches_epreuve.dart';
import '../../domain/entities/affiche_epreuve.dart';
import '../../domain/entities/fichier_affiche_epreuve.dart';
import '../../domain/services/validation_affiche_epreuve.dart';
import '../../infrastructure/media/source_fichier_affiche_image_picker.dart';

class AffichesEpreuveController extends ChangeNotifier {
  AffichesEpreuveController(this._gerer, this._source);

  final GererAffichesEpreuve _gerer;
  final SourceFichierAffiche _source;

  List<AfficheEpreuve> _affiches = const [];
  final Map<String, Uri> _urls = {};
  bool _chargement = false;
  bool _operationEnCours = false;
  String? _afficheEnCoursId;
  String? _erreur;
  bool _detruit = false;

  List<AfficheEpreuve> get affiches => List.unmodifiable(_affiches);
  bool get chargement => _chargement;
  bool get operationEnCours => _operationEnCours;
  String? get afficheEnCoursId => _afficheEnCoursId;
  String? get erreur => _erreur;
  Uri? urlPour(String afficheId) => _urls[afficheId];

  Future<void> charger(String epreuveId) async {
    if (_chargement || _operationEnCours || _detruit) return;
    _chargement = true;
    _erreur = null;
    _notifier();
    try {
      final valeurs = await _gerer.lister(epreuveId);
      final urls = <String, Uri>{};
      for (final affiche in valeurs) {
        urls[affiche.id] = await _gerer.obtenirUrlConsultation(affiche);
      }
      if (_detruit) return;
      _affiches = valeurs;
      _urls
        ..clear()
        ..addAll(urls);
    } catch (e) {
      if (!_detruit) _erreur = _message(e);
    } finally {
      _chargement = false;
      _notifier();
    }
  }

  /// Sélectionne et valide un fichier sans l'envoyer. Ce parcours permet au
  /// formulaire de création de conserver ses affiches avant que l'épreuve ait
  /// reçu son identifiant serveur.
  Future<FichierAfficheEpreuve?> selectionnerFichier() async {
    if (!_commencerOperation()) return null;
    try {
      final fichier = await _source.selectionner();
      if (fichier != null) ValidationAfficheEpreuve.verifierFichier(fichier);
      return fichier;
    } catch (e) {
      _erreur = _message(e);
      return null;
    } finally {
      _terminerOperation();
    }
  }

  Future<bool> ajouterFichier({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    if (!_commencerOperation()) return false;
    try {
      final nouvelle = await _gerer.ajouter(
        epreuveId: epreuveId,
        position: position,
        texteAlternatif: texteAlternatif,
        fichier: fichier,
      );
      final url = await _gerer.obtenirUrlConsultation(nouvelle);
      _affiches = [..._affiches, nouvelle]
        ..sort((a, b) => a.position.compareTo(b.position));
      _urls[nouvelle.id] = url;
      return true;
    } catch (e) {
      _erreur = _message(e);
      return false;
    } finally {
      _terminerOperation();
    }
  }

  Future<bool> ajouterDepuisGalerie({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
  }) async {
    final fichier = await selectionnerFichier();
    if (fichier == null) return false;
    return ajouterFichier(
      epreuveId: epreuveId,
      position: position,
      texteAlternatif: texteAlternatif,
      fichier: fichier,
    );
  }

  Future<bool> remplacerDepuisGalerie({
    required AfficheEpreuve affiche,
    required String texteAlternatif,
  }) async {
    if (!_commencerOperation(affiche.id)) return false;
    try {
      final fichier = await _source.selectionner();
      if (fichier == null) return false;
      final remplacee = await _gerer.remplacer(
        affiche: affiche,
        texteAlternatif: texteAlternatif,
        fichier: fichier,
      );
      final url = await _gerer.obtenirUrlConsultation(remplacee);
      _remplacerLocalement(remplacee);
      _urls[remplacee.id] = url;
      return true;
    } catch (e) {
      _erreur = _message(e);
      return false;
    } finally {
      _terminerOperation();
    }
  }

  Future<bool> modifierTexteAlternatif({
    required AfficheEpreuve affiche,
    required String texteAlternatif,
  }) async {
    if (!_commencerOperation(affiche.id)) return false;
    try {
      final modifiee = await _gerer.modifierTexteAlternatif(
        affiche: affiche,
        texteAlternatif: texteAlternatif,
      );
      _remplacerLocalement(modifiee);
      return true;
    } catch (e) {
      _erreur = _message(e);
      return false;
    } finally {
      _terminerOperation();
    }
  }

  Future<bool> inverser(String epreuveId) async {
    if (_affiches.length != 2 || !_commencerOperation()) return false;
    try {
      _affiches = await _gerer.reordonner(
        epreuveId: epreuveId,
        afficheIds: [_affiches[1].id, _affiches[0].id],
      );
      return true;
    } catch (e) {
      _erreur = _message(e);
      return false;
    } finally {
      _terminerOperation();
    }
  }

  Future<bool> supprimer(AfficheEpreuve affiche) async {
    if (!_commencerOperation(affiche.id)) return false;
    try {
      _affiches = await _gerer.supprimer(affiche);
      _urls.remove(affiche.id);
      return true;
    } catch (e) {
      _erreur = _message(e);
      return false;
    } finally {
      _terminerOperation();
    }
  }

  void effacerErreur() {
    if (_erreur == null) return;
    _erreur = null;
    _notifier();
  }

  void reinitialiser() {
    if (_operationEnCours) return;
    _affiches = const [];
    _urls.clear();
    _erreur = null;
    _notifier();
  }

  bool _commencerOperation([String? afficheId]) {
    if (_chargement || _operationEnCours || _detruit) return false;
    _operationEnCours = true;
    _afficheEnCoursId = afficheId;
    _erreur = null;
    _notifier();
    return true;
  }

  void _terminerOperation() {
    _operationEnCours = false;
    _afficheEnCoursId = null;
    _notifier();
  }

  void _remplacerLocalement(AfficheEpreuve affiche) {
    _affiches = [
      for (final valeur in _affiches)
        valeur.id == affiche.id ? affiche : valeur,
    ]..sort((a, b) => a.position.compareTo(b.position));
  }

  String _message(Object erreur) => erreur
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');

  void _notifier() {
    if (!_detruit) notifyListeners();
  }

  @override
  void dispose() {
    _detruit = true;
    super.dispose();
  }
}
