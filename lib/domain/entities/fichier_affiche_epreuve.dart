import 'dart:typed_data';

class FichierAfficheEpreuve {
  FichierAfficheEpreuve({
    required Uint8List contenu,
    required String typeMime,
    required this.largeurPixels,
    required this.hauteurPixels,
  }) : _contenu = Uint8List.fromList(contenu),
       typeMime = typeMime.trim().toLowerCase();

  final Uint8List _contenu;
  final String typeMime;
  final int largeurPixels;
  final int hauteurPixels;

  int get tailleOctets => _contenu.length;

  /// Retourne une copie afin que le contenu validé ne puisse pas être modifié.
  Uint8List get contenu => Uint8List.fromList(_contenu);
}
