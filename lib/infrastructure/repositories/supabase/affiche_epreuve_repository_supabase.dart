import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/affiche_epreuve.dart';
import '../../../domain/entities/fichier_affiche_epreuve.dart';
import '../../../domain/ports/affiche_epreuve_repository.dart';
import '../../mappers/affiche_epreuve_supabase_mapper.dart';

class AfficheEpreuveRepositorySupabase implements AfficheEpreuveRepository {
  AfficheEpreuveRepositorySupabase(
    this._client, {
    this._mapper = const AfficheEpreuveSupabaseMapper(),
  });

  static const _bucket = 'affiches-epreuves';
  static const _colonnes =
      'id,epreuve_id,position,objet_path,mime_type,taille_octets,largeur,'
      'hauteur,texte_alternatif,version,date_creation,date_modification';

  final SupabaseClient _client;
  final AfficheEpreuveSupabaseMapper _mapper;
  final Random _aleatoire = Random.secure();

  @override
  Future<List<AfficheEpreuve>> obtenirParEpreuve(String epreuveId) async {
    try {
      final lignes = await _client
          .from('affiches_epreuve')
          .select(_colonnes)
          .eq('epreuve_id', epreuveId)
          .order('position');
      return lignes.map(_mapper.convertir).toList();
    } on PostgrestException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<Uri> obtenirUrlConsultation(String afficheId) async {
    try {
      final ligne = await _obtenirLigne(afficheId);
      final url = await _client.storage
          .from(_bucket)
          .createSignedUrl(ligne.objetPath, 600);
      return Uri.parse(url);
    } on StorageException catch (e) {
      throw StateError(_messageStorage(e));
    } on PostgrestException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<AfficheEpreuve> ajouter({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) {
    return _enregistrer(
      epreuveId: epreuveId,
      position: position,
      texteAlternatif: texteAlternatif,
      fichier: fichier,
    );
  }

  @override
  Future<AfficheEpreuve> remplacer({
    required String afficheId,
    required String epreuveId,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    final ligne = await _obtenirLigne(afficheId);
    if (ligne.affiche.epreuveId != epreuveId) {
      throw StateError('Cette affiche n’appartient pas à l’épreuve.');
    }
    return _enregistrer(
      epreuveId: epreuveId,
      position: ligne.affiche.position,
      texteAlternatif: texteAlternatif,
      fichier: fichier,
    );
  }

  Future<AfficheEpreuve> _enregistrer({
    required String epreuveId,
    required int position,
    required String texteAlternatif,
    required FichierAfficheEpreuve fichier,
  }) async {
    String? nouveauPath;
    try {
      final competitionId = await _obtenirCompetitionId(epreuveId);
      final extension = switch (fichier.typeMime) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => throw StateError('Format d’affiche non pris en charge.'),
      };
      nouveauPath = '$competitionId/$epreuveId/${_genererUuid()}.$extension';
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            nouveauPath,
            fichier.contenu,
            fileOptions: FileOptions(
              contentType: fichier.typeMime,
              upsert: false,
            ),
          );
      final resultat = Map<String, dynamic>.from(
        await _client.rpc(
          'enregistrer_affiche_epreuve',
          params: {
            'p_epreuve_id': epreuveId,
            'p_position': position,
            'p_objet_path': nouveauPath,
            'p_mime_type': fichier.typeMime,
            'p_taille_octets': fichier.tailleOctets,
            'p_largeur': fichier.largeurPixels,
            'p_hauteur': fichier.hauteurPixels,
            'p_texte_alternatif': texteAlternatif,
          },
        ) as Map,
      );
      final ancienPath = resultat.remove('ancien_objet_path') as String?;
      if (ancienPath != null && ancienPath != nouveauPath) {
        await _supprimerObjetSansMasquerSucces(ancienPath);
      }
      return _mapper.convertir(resultat);
    } on StorageException catch (e) {
      if (nouveauPath != null) {
        await _supprimerObjetSansMasquerSucces(nouveauPath);
      }
      throw StateError(_messageStorage(e));
    } on PostgrestException catch (e) {
      if (nouveauPath != null) {
        await _supprimerObjetSansMasquerSucces(nouveauPath);
      }
      throw StateError(_message(e));
    } catch (_) {
      if (nouveauPath != null) {
        await _supprimerObjetSansMasquerSucces(nouveauPath);
      }
      rethrow;
    }
  }

  @override
  Future<AfficheEpreuve> modifierTexteAlternatif({
    required String afficheId,
    required String epreuveId,
    required String texteAlternatif,
  }) async {
    try {
      final resultat = await _client.rpc(
        'modifier_texte_alternatif_affiche_epreuve',
        params: {
          'p_affiche_id': afficheId,
          'p_epreuve_id': epreuveId,
          'p_texte_alternatif': texteAlternatif,
        },
      );
      return _mapper.convertir(Map<String, dynamic>.from(resultat as Map));
    } on PostgrestException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<AfficheEpreuve>> reordonner({
    required String epreuveId,
    required List<String> afficheIds,
  }) async {
    final actuelles = await obtenirParEpreuve(epreuveId);
    if (actuelles.map((a) => a.id).toList().join('|') == afficheIds.join('|')) {
      return actuelles;
    }
    final idsActuels = actuelles.map((a) => a.id).toSet();
    if (actuelles.length != 2 ||
        afficheIds.length != 2 ||
        idsActuels.difference(afficheIds.toSet()).isNotEmpty) {
      throw StateError('L’ordre des affiches est incohérent.');
    }
    try {
      await _client.rpc(
        'reordonner_affiches_epreuve',
        params: {'p_epreuve_id': epreuveId},
      );
      return await obtenirParEpreuve(epreuveId);
    } on PostgrestException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<AfficheEpreuve>> supprimer({
    required String afficheId,
    required String epreuveId,
  }) async {
    final ligne = await _obtenirLigne(afficheId);
    if (ligne.affiche.epreuveId != epreuveId) {
      throw StateError('Cette affiche n’appartient pas à l’épreuve.');
    }
    try {
      final path = await _client.rpc(
        'supprimer_affiche_epreuve',
        params: {
          'p_epreuve_id': epreuveId,
          'p_position': ligne.affiche.position,
        },
      ) as String;
      await _supprimerObjetSansMasquerSucces(path);
      return await obtenirParEpreuve(epreuveId);
    } on PostgrestException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<_LigneAffiche> _obtenirLigne(String afficheId) async {
    final ligne = await _client
        .from('affiches_epreuve')
        .select(_colonnes)
        .eq('id', afficheId)
        .maybeSingle();
    if (ligne == null) throw StateError('Cette affiche est introuvable.');
    return _LigneAffiche(
      _mapper.convertir(ligne),
      ligne['objet_path'] as String,
    );
  }

  Future<String> _obtenirCompetitionId(String epreuveId) async {
    final ligne = await _client
        .from('epreuves')
        .select('competition_id')
        .eq('id', epreuveId)
        .maybeSingle();
    if (ligne == null) throw StateError('Cette épreuve est introuvable.');
    return ligne['competition_id'] as String;
  }

  Future<void> _supprimerObjetSansMasquerSucces(String path) async {
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // Le nettoyage serveur des orphelins constitue la seconde protection.
    }
  }

  String _genererUuid() {
    final octets = List<int>.generate(16, (_) => _aleatoire.nextInt(256));
    octets[6] = (octets[6] & 0x0f) | 0x40;
    octets[8] = (octets[8] & 0x3f) | 0x80;
    final texte = octets
        .map((octet) => octet.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${texte.substring(0, 8)}-'
        '${texte.substring(8, 12)}-'
        '${texte.substring(12, 16)}-'
        '${texte.substring(16, 20)}-'
        '${texte.substring(20)}';
  }

  String _message(PostgrestException e) {
    if (e.code == '42501') {
      return 'Seul le coach responsable peut modifier les affiches de cette épreuve en brouillon.';
    }
    if (e.code == 'PGRST202') {
      return 'La gestion des affiches doit être activée sur le serveur.';
    }
    return e.message;
  }

  String _messageStorage(StorageException e) {
    if (e.statusCode == '413') {
      return 'L’affiche dépasse la taille maximale de 5 Mo.';
    }
    if (e.statusCode == '403') {
      return 'Tu n’es pas autorisé à modifier cette affiche.';
    }
    return 'Impossible de transférer l’affiche. Vérifie ta connexion puis réessaie.';
  }
}

class _LigneAffiche {
  const _LigneAffiche(this.affiche, this.objetPath);

  final AfficheEpreuve affiche;
  final String objetPath;
}
