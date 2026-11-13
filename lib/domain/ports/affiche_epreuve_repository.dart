import '../entities/affiche_epreuve.dart';
import '../entities/fichier_affiche_epreuve.dart';

abstract interface class AfficheEpreuveRepository {
  /// Retourne les affiches dans leur ordre de présentation.
  Future<List<AfficheEpreuve>> obtenirParEpreuve(String epreuveId);

  /// Produit une URL de lecture temporaire pour une affiche autorisée.
  Future<Uri> obtenirUrlConsultation(String afficheId);

  /// Ajoute le fichier et ses métadonnées de manière cohérente.
  Future<AfficheEpreuve> ajouter({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  });

  /// Remplace le fichier après validation, puis nettoie l'ancien objet.
  Future<AfficheEpreuve> remplacer({
    required String afficheId,
    required String epreuveId,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  });

  Future<AfficheEpreuve> modifierTexteAlternatif({
    required String afficheId,
    required String epreuveId,
    required String texteAlternatif,
  });

  /// Applique l'ordre complet dans une seule transaction.
  Future<List<AfficheEpreuve>> reordonner({
    required String epreuveId,
    required List<String> afficheIds,
  });

  /// Supprime l'objet et promeut l'éventuelle seconde affiche.
  Future<List<AfficheEpreuve>> supprimer({
    required String afficheId,
    required String epreuveId,
  });
}
