import '../../domain/entities/fichier_affiche_epreuve.dart';

class AfficheEpreuveEnAttente {
  const AfficheEpreuveEnAttente({
    required this.fichier,
    required this.texteAlternatif,
  });

  final FichierAfficheEpreuve fichier;
  final String texteAlternatif;

  AfficheEpreuveEnAttente copierAvec({String? texteAlternatif}) {
    return AfficheEpreuveEnAttente(
      fichier: fichier,
      texteAlternatif: texteAlternatif ?? this.texteAlternatif,
    );
  }
}
