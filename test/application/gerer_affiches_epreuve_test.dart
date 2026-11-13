import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/application/use_cases/epreuve/gerer_affiches_epreuve.dart';
import 'package:triathlon/application/use_cases/epreuve/verifier_competition_brouillon.dart';
import 'package:triathlon/domain/entities/affiche_epreuve.dart';
import 'package:triathlon/domain/entities/competition.dart';
import 'package:triathlon/domain/entities/epreuve.dart';
import 'package:triathlon/domain/entities/fichier_affiche_epreuve.dart';
import 'package:triathlon/domain/entities/statut_competition.dart';
import 'package:triathlon/domain/entities/type_discipline.dart';
import 'package:triathlon/domain/ports/affiche_epreuve_repository.dart';
import 'package:triathlon/domain/ports/competition_repository.dart';
import 'package:triathlon/domain/ports/epreuve_repository.dart';

final epreuveAffiches = Epreuve(
  id: 'epreuve-1',
  competitionId: 'competition-1',
  discipline: TypeDiscipline.natation,
  nom: 'Natation',
  distanceMetres: 500,
  nombreManches: 2,
  ordre: 1,
  dureeLimiteSecondes: 60,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
);

AfficheEpreuve affiche({
  required String id,
  required int position,
  String epreuveId = 'epreuve-1',
}) => AfficheEpreuve(
  id: id,
  epreuveId: epreuveId,
  position: position,
  texteAlternatif: 'Affiche de la compétition',
  typeMime: 'image/jpeg',
  tailleOctets: 3,
  largeurPixels: 100,
  hauteurPixels: 200,
  version: 1,
  dateCreation: DateTime(2026),
  dateModification: DateTime(2026),
);

FichierAfficheEpreuve fichier({
  String typeMime = 'image/jpeg',
  int largeur = 100,
  int hauteur = 200,
  int taille = 3,
}) => FichierAfficheEpreuve(
  contenu: Uint8List(taille),
  typeMime: typeMime,
  largeurPixels: largeur,
  hauteurPixels: hauteur,
);

class CompetitionsAffichesFake extends Fake implements CompetitionRepository {
  StatutCompetition statut = StatutCompetition.brouillon;

  @override
  Future<Competition?> obtenirParId(String id) async => Competition(
    id: id,
    nom: 'Triathlon',
    dateCompetition: DateTime(2026),
    coachId: 'coach',
    statut: statut,
    dateCreation: DateTime(2026),
    dateModification: DateTime(2026),
    demarrageAutomatiqueMancheSuivante: false,
  );
}

class EpreuvesAffichesFake extends Fake implements EpreuveRepository {
  Epreuve? valeur = epreuveAffiches;

  @override
  Future<Epreuve?> obtenirParId(String id) async =>
      valeur?.id == id ? valeur : null;
}

class AffichesFake extends Fake implements AfficheEpreuveRepository {
  List<AfficheEpreuve> valeurs = [];
  int mutations = 0;
  String? dernierTexte;
  FichierAfficheEpreuve? dernierFichier;

  @override
  Future<List<AfficheEpreuve>> obtenirParEpreuve(String epreuveId) async =>
      valeurs.where((a) => a.epreuveId == epreuveId).toList();

  @override
  Future<Uri> obtenirUrlConsultation(String afficheId) async =>
      Uri.parse('https://exemple.test/$afficheId');

  @override
  Future<AfficheEpreuve> ajouter({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    mutations++;
    dernierTexte = texteAlternatif;
    dernierFichier = fichier;
    valeurs = [
      for (final valeur in valeurs)
        valeur.position >= position
            ? valeur.copierAvec(position: valeur.position + 1)
            : valeur,
    ];
    final nouvelle = AfficheEpreuve(
      id: 'affiche-${valeurs.length + 1}',
      epreuveId: epreuveId,
      position: position,
      texteAlternatif: texteAlternatif,
      typeMime: fichier.typeMime,
      tailleOctets: fichier.tailleOctets,
      largeurPixels: fichier.largeurPixels,
      hauteurPixels: fichier.hauteurPixels,
      version: 1,
      dateCreation: DateTime(2026),
      dateModification: DateTime(2026),
    );
    valeurs = [...valeurs, nouvelle];
    return nouvelle;
  }

  @override
  Future<AfficheEpreuve> remplacer({
    required String afficheId,
    required String epreuveId,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    mutations++;
    dernierTexte = texteAlternatif;
    dernierFichier = fichier;
    final actuelle = valeurs.firstWhere((a) => a.id == afficheId);
    final remplacee = actuelle.copierAvec(
      texteAlternatif: texteAlternatif,
      typeMime: fichier.typeMime,
      tailleOctets: fichier.tailleOctets,
      largeurPixels: fichier.largeurPixels,
      hauteurPixels: fichier.hauteurPixels,
      version: actuelle.version + 1,
    );
    valeurs = [
      for (final valeur in valeurs) valeur.id == afficheId ? remplacee : valeur,
    ];
    return remplacee;
  }

  @override
  Future<AfficheEpreuve> modifierTexteAlternatif({
    required String afficheId,
    required String epreuveId,
    required String texteAlternatif,
  }) async {
    mutations++;
    dernierTexte = texteAlternatif;
    final actuelle = valeurs.firstWhere((a) => a.id == afficheId);
    final modifiee = actuelle.copierAvec(texteAlternatif: texteAlternatif);
    valeurs = [
      for (final valeur in valeurs) valeur.id == afficheId ? modifiee : valeur,
    ];
    return modifiee;
  }

  @override
  Future<List<AfficheEpreuve>> reordonner({
    required String epreuveId,
    required List<String> afficheIds,
  }) async {
    mutations++;
    valeurs = [
      for (var i = 0; i < afficheIds.length; i++)
        valeurs
            .firstWhere((a) => a.id == afficheIds[i])
            .copierAvec(position: i + 1),
    ];
    return valeurs;
  }

  @override
  Future<List<AfficheEpreuve>> supprimer({
    required String afficheId,
    required String epreuveId,
  }) async {
    mutations++;
    final restantes = valeurs.where((a) => a.id != afficheId).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    valeurs = [
      for (var i = 0; i < restantes.length; i++)
        restantes[i].copierAvec(position: i + 1),
    ];
    return valeurs;
  }
}

void main() {
  late CompetitionsAffichesFake competitions;
  late EpreuvesAffichesFake epreuves;
  late AffichesFake affiches;
  late GererAffichesEpreuve gerer;

  setUp(() {
    competitions = CompetitionsAffichesFake();
    epreuves = EpreuvesAffichesFake();
    affiches = AffichesFake();
    gerer = GererAffichesEpreuve(
      affiches,
      epreuves,
      VerifierCompetitionBrouillon(competitions),
    );
  });

  test('ajoute une affiche valide et normalise son texte', () async {
    final resultat = await gerer.ajouter(
      epreuveId: epreuveAffiches.id,
      position: 1,
      texteAlternatif: '  Départ de la course  ',
      fichier: fichier(typeMime: ' IMAGE/PNG '),
    );

    expect(resultat.position, 1);
    expect(affiches.dernierTexte, 'Départ de la course');
    expect(affiches.dernierFichier?.typeMime, 'image/png');
    expect(affiches.mutations, 1);
  });

  test('refuse une troisième affiche sans appeler le dépôt', () async {
    affiches.valeurs = [
      affiche(id: 'a1', position: 1),
      affiche(id: 'a2', position: 2),
    ];

    await expectLater(
      gerer.ajouter(
        epreuveId: epreuveAffiches.id,
        position: 2,
        texteAlternatif: 'Troisième affiche',
        fichier: fichier(),
      ),
      throwsStateError,
    );
    expect(affiches.mutations, 0);
  });

  test('refuse formats, dimensions, taille et texte invalides', () async {
    final cas = <Future<void> Function()>[
      () async => gerer.ajouter(
        epreuveId: epreuveAffiches.id,
        position: 1,
        texteAlternatif: 'Affiche valide',
        fichier: fichier(typeMime: 'image/gif'),
      ),
      () async => gerer.ajouter(
        epreuveId: epreuveAffiches.id,
        position: 1,
        texteAlternatif: 'Affiche valide',
        fichier: fichier(largeur: 4097),
      ),
      () async => gerer.ajouter(
        epreuveId: epreuveAffiches.id,
        position: 1,
        texteAlternatif: 'Affiche valide',
        fichier: fichier(taille: 5 * 1024 * 1024 + 1),
      ),
      () async => gerer.ajouter(
        epreuveId: epreuveAffiches.id,
        position: 1,
        texteAlternatif: 'x',
        fichier: fichier(),
      ),
    ];

    for (final executer in cas) {
      await expectLater(executer(), throwsArgumentError);
    }
    expect(affiches.mutations, 0);
  });

  test(
    'autorise la lecture mais refuse les mutations hors brouillon',
    () async {
      affiches.valeurs = [affiche(id: 'a1', position: 1)];
      competitions.statut = StatutCompetition.ouverte;

      expect(await gerer.lister(epreuveAffiches.id), hasLength(1));
      await expectLater(
        gerer.modifierTexteAlternatif(
          affiche: affiches.valeurs.single,
          texteAlternatif: 'Nouveau texte',
        ),
        throwsStateError,
      );
      expect(affiches.mutations, 0);
    },
  );

  test('réordonne uniquement une liste complète sans doublon', () async {
    affiches.valeurs = [
      affiche(id: 'a1', position: 1),
      affiche(id: 'a2', position: 2),
    ];

    await expectLater(
      gerer.reordonner(epreuveId: epreuveAffiches.id, afficheIds: ['a1', 'a1']),
      throwsArgumentError,
    );
    final resultat = await gerer.reordonner(
      epreuveId: epreuveAffiches.id,
      afficheIds: ['a2', 'a1'],
    );

    expect(resultat.map((a) => a.id), ['a2', 'a1']);
    expect(resultat.map((a) => a.position), [1, 2]);
    expect(affiches.mutations, 1);
  });

  test('remplace puis supprime et promeut la seconde affiche', () async {
    affiches.valeurs = [
      affiche(id: 'a1', position: 1),
      affiche(id: 'a2', position: 2),
    ];

    final remplacee = await gerer.remplacer(
      affiche: affiches.valeurs.first,
      texteAlternatif: 'Affiche principale remplacée',
      fichier: fichier(typeMime: 'image/webp'),
    );
    expect(remplacee.version, 2);
    expect(remplacee.typeMime, 'image/webp');

    final restantes = await gerer.supprimer(remplacee);
    expect(restantes, hasLength(1));
    expect(restantes.single.id, 'a2');
    expect(restantes.single.position, 1);
  });

  test('le contenu du fichier reste immuable après validation', () {
    final source = Uint8List.fromList([1, 2, 3]);
    final valeur = FichierAfficheEpreuve(
      contenu: source,
      typeMime: 'image/jpeg',
      largeurPixels: 10,
      hauteurPixels: 10,
    );

    source[0] = 9;
    final copie = valeur.contenu;
    copie[1] = 9;

    expect(valeur.contenu, [1, 2, 3]);
  });
}
