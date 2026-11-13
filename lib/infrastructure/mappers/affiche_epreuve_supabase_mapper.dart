import '../../domain/entities/affiche_epreuve.dart';

class AfficheEpreuveSupabaseMapper {
  const AfficheEpreuveSupabaseMapper();

  AfficheEpreuve convertir(Map<String, dynamic> donnees) {
    return AfficheEpreuve(
      id: donnees['id'] as String,
      epreuveId: donnees['epreuve_id'] as String,
      position: (donnees['position'] as num).toInt(),
      texteAlternatif: donnees['texte_alternatif'] as String,
      typeMime: donnees['mime_type'] as String,
      tailleOctets: (donnees['taille_octets'] as num).toInt(),
      largeurPixels: (donnees['largeur'] as num).toInt(),
      hauteurPixels: (donnees['hauteur'] as num).toInt(),
      version: (donnees['version'] as num).toInt(),
      dateCreation: DateTime.parse(donnees['date_creation'] as String),
      dateModification: DateTime.parse(donnees['date_modification'] as String),
    );
  }
}
