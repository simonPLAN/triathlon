import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/infrastructure/mappers/affiche_epreuve_supabase_mapper.dart';

void main() {
  test('convertit les métadonnées Supabase d’une affiche', () {
    final affiche = const AfficheEpreuveSupabaseMapper().convertir({
      'id': 'a1',
      'epreuve_id': 'e1',
      'position': 1,
      'objet_path': 'c/e/a.png',
      'mime_type': 'image/png',
      'taille_octets': 123,
      'largeur': 800,
      'hauteur': 1200,
      'texte_alternatif': 'Affiche de natation',
      'version': 2,
      'date_creation': '2026-11-13T10:00:00Z',
      'date_modification': '2026-11-13T11:00:00Z',
    });

    expect(affiche.id, 'a1');
    expect(affiche.epreuveId, 'e1');
    expect(affiche.estPrincipale, isTrue);
    expect(affiche.tailleOctets, 123);
    expect(affiche.largeurPixels, 800);
    expect(affiche.version, 2);
    expect(affiche.dateModification.isUtc, isTrue);
  });
}
