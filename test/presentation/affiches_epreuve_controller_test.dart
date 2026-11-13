import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/epreuve/gerer_affiches_epreuve.dart';
import 'package:triathlon/domain/entities/affiche_epreuve.dart';
import 'package:triathlon/domain/entities/fichier_affiche_epreuve.dart';
import 'package:triathlon/infrastructure/media/source_fichier_affiche_image_picker.dart';
import 'package:triathlon/presentation/controllers/affiches_epreuve_controller.dart';

AfficheEpreuve _affiche(String id, int position) => AfficheEpreuve(
  id: id,
  epreuveId: 'e1',
  position: position,
  texteAlternatif: 'Affiche numéro $position',
  typeMime: 'image/png',
  tailleOctets: 4,
  largeurPixels: 10,
  hauteurPixels: 10,
  version: 1,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
);

class _GererFake extends Fake implements GererAffichesEpreuve {
  List<AfficheEpreuve> valeurs = [_affiche('a1', 1)];
  int ajouts = 0;

  @override
  Future<List<AfficheEpreuve>> lister(String epreuveId) async => valeurs;

  @override
  Future<Uri> obtenirUrlConsultation(AfficheEpreuve affiche) async =>
      Uri.parse('https://exemple.test/${affiche.id}');

  @override
  Future<AfficheEpreuve> ajouter({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    ajouts++;
    final resultat = _affiche(
      'a2',
      position,
    ).copierAvec(texteAlternatif: texteAlternatif);
    valeurs = [...valeurs, resultat];
    return resultat;
  }
}

class _SourceFake implements SourceFichierAffiche {
  FichierAfficheEpreuve? valeur;

  @override
  Future<FichierAfficheEpreuve?> selectionner() async => valeur;
}

void main() {
  test('charge les affiches et leurs URL privées', () async {
    final controller = AffichesEpreuveController(_GererFake(), _SourceFake());
    addTearDown(controller.dispose);

    await controller.charger('e1');

    expect(controller.affiches.map((a) => a.id), ['a1']);
    expect(controller.urlPour('a1'), Uri.parse('https://exemple.test/a1'));
    expect(controller.chargement, isFalse);
    expect(controller.erreur, isNull);
  });

  test('une sélection annulée ne crée rien et libère l’opération', () async {
    final gerer = _GererFake();
    final controller = AffichesEpreuveController(gerer, _SourceFake());
    addTearDown(controller.dispose);

    final succes = await controller.ajouterDepuisGalerie(
      epreuveId: 'e1',
      position: 2,
      texteAlternatif: 'Deuxième affiche',
    );

    expect(succes, isFalse);
    expect(gerer.ajouts, 0);
    expect(controller.operationEnCours, isFalse);
    expect(controller.erreur, isNull);
  });

  test('sélectionne avant création sans envoyer le fichier', () async {
    final gerer = _GererFake();
    final source = _SourceFake()
      ..valeur = FichierAfficheEpreuve(
        contenu: Uint8List.fromList([1, 2, 3, 4]),
        typeMime: 'image/png',
        largeurPixels: 10,
        hauteurPixels: 10,
      );
    final controller = AffichesEpreuveController(gerer, source);
    addTearDown(controller.dispose);

    final selection = await controller.selectionnerFichier();

    expect(selection, isNotNull);
    expect(gerer.ajouts, 0);
    expect(controller.operationEnCours, isFalse);
    final succes = await controller.ajouterFichier(
      epreuveId: 'e1',
      position: 2,
      texteAlternatif: 'Affiche conservée dans le formulaire',
      fichier: selection!,
    );
    expect(succes, isTrue);
    expect(gerer.ajouts, 1);
  });

  test('ajoute une sélection et expose son URL', () async {
    final gerer = _GererFake();
    final source = _SourceFake()
      ..valeur = FichierAfficheEpreuve(
        contenu: Uint8List.fromList([1, 2, 3, 4]),
        typeMime: 'image/png',
        largeurPixels: 10,
        hauteurPixels: 10,
      );
    final controller = AffichesEpreuveController(gerer, source);
    addTearDown(controller.dispose);
    await controller.charger('e1');

    final succes = await controller.ajouterDepuisGalerie(
      epreuveId: 'e1',
      position: 2,
      texteAlternatif: 'Deuxième affiche',
    );

    expect(succes, isTrue);
    expect(controller.affiches.map((a) => a.id), ['a1', 'a2']);
    expect(controller.urlPour('a2'), Uri.parse('https://exemple.test/a2'));
    expect(controller.operationEnCours, isFalse);
  });
}
