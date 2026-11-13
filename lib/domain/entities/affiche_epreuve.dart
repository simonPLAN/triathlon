class AfficheEpreuve {
  const AfficheEpreuve({
    required this.id,
    required this.epreuveId,
    required this.position,
    required this.texteAlternatif,
    required this.typeMime,
    required this.tailleOctets,
    required this.largeurPixels,
    required this.hauteurPixels,
    required this.version,
    required this.dateCreation,
    required this.dateModification,
  });

  final String id;
  final String epreuveId;

  /// Position stable dans la galerie : 1 est l'affiche principale.
  final int position;
  final String texteAlternatif;
  final String typeMime;
  final int tailleOctets;
  final int largeurPixels;
  final int hauteurPixels;

  /// Change à chaque remplacement afin d'invalider les caches de consultation.
  final int version;
  final DateTime dateCreation;
  final DateTime dateModification;

  bool get estPrincipale => position == 1;

  AfficheEpreuve copierAvec({
    String? id,
    String? epreuveId,
    int? position,
    String? texteAlternatif,
    String? typeMime,
    int? tailleOctets,
    int? largeurPixels,
    int? hauteurPixels,
    int? version,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return AfficheEpreuve(
      id: id ?? this.id,
      epreuveId: epreuveId ?? this.epreuveId,
      position: position ?? this.position,
      texteAlternatif: texteAlternatif ?? this.texteAlternatif,
      typeMime: typeMime ?? this.typeMime,
      tailleOctets: tailleOctets ?? this.tailleOctets,
      largeurPixels: largeurPixels ?? this.largeurPixels,
      hauteurPixels: hauteurPixels ?? this.hauteurPixels,
      version: version ?? this.version,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
