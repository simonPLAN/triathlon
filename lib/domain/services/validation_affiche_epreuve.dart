import '../entities/fichier_affiche_epreuve.dart';

class ValidationAfficheEpreuve {
  const ValidationAfficheEpreuve._();

  static const int nombreMaximum = 2;
  static const int tailleMaximaleOctets = 5 * 1024 * 1024;
  static const int dimensionMaximalePixels = 4096;
  static const int longueurTexteMinimum = 3;
  static const int longueurTexteMaximum = 300;
  static const Set<String> typesMimeAutorises = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static String normaliserTexteAlternatif(String valeur) {
    final texte = valeur.trim();
    if (texte.length < longueurTexteMinimum ||
        texte.length > longueurTexteMaximum) {
      throw ArgumentError(
        'Le texte alternatif doit contenir entre '
        '$longueurTexteMinimum et $longueurTexteMaximum caractères.',
      );
    }
    return texte;
  }

  static void verifierFichier(FichierAfficheEpreuve fichier) {
    if (!typesMimeAutorises.contains(fichier.typeMime)) {
      throw ArgumentError(
        'Format non accepté. Utilise une image JPEG, PNG ou WebP.',
      );
    }
    if (fichier.tailleOctets < 1 ||
        fichier.tailleOctets > tailleMaximaleOctets) {
      throw ArgumentError('L’affiche doit peser au maximum 5 Mo.');
    }
    if (fichier.largeurPixels < 1 ||
        fichier.hauteurPixels < 1 ||
        fichier.largeurPixels > dimensionMaximalePixels ||
        fichier.hauteurPixels > dimensionMaximalePixels) {
      throw ArgumentError(
        'L’affiche ne doit pas dépasser '
        '$dimensionMaximalePixels × $dimensionMaximalePixels pixels.',
      );
    }
  }

  static void verifierPosition(int position, {required int nombreActuel}) {
    final positionMaximale = nombreActuel + 1;
    if (position < 1 ||
        position > nombreMaximum ||
        position > positionMaximale) {
      throw ArgumentError('La position de l’affiche est invalide.');
    }
  }
}
