import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/fichier_affiche_epreuve.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/ports/competition_repository.dart';

class CompetitionRepositorySupabase implements CompetitionRepository {
  CompetitionRepositorySupabase(this._client);

  static const _nomTable = 'competitions';
  static const _bucketImages = 'images-competitions';
  static const _colonnes =
      'id, nom, description, lieu, date_competition, statut, coach_id, '
      'date_creation, date_modification, demarrage_automatique_manche_suivante, '
      'image_path';

  final SupabaseClient _client;
  final Random _aleatoire = Random.secure();

  @override
  Future<List<Competition>> obtenirToutes() async {
    final utilisateur = _utilisateurConnecte();
    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_colonnes)
          .eq('coach_id', utilisateur.id)
          .order('date_competition');
      return await Future.wait(donnees.map(_convertirDepuisSupabase));
    } on PostgrestException catch (e) {
      throw Exception('Impossible de charger les compétitions : ${e.message}');
    }
  }

  @override
  Future<Competition?> obtenirParId(String id) async {
    final utilisateur = _utilisateurConnecte();
    final idNettoye = id.trim();
    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }
    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_colonnes)
          .eq('id', idNettoye)
          .eq('coach_id', utilisateur.id)
          .maybeSingle();
      return donnees == null ? null : await _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (e) {
      throw Exception('Impossible de récupérer la compétition : ${e.message}');
    }
  }

  @override
  Future<Competition> creer(Competition competition) async {
    final utilisateur = _utilisateurConnecte();
    if (competition.coachId != utilisateur.id) {
      throw StateError('La compétition doit appartenir au coach connecté.');
    }
    try {
      final donnees = await _client
          .from(_nomTable)
          .insert(_convertirPourCreation(competition))
          .select(_colonnes)
          .single();
      return await _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (e) {
      throw Exception('Impossible de créer la compétition : ${e.message}');
    }
  }

  @override
  Future<Competition> modifier(Competition competition) async {
    final utilisateur = _utilisateurConnecte();
    if (competition.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }
    if (competition.coachId != utilisateur.id) {
      throw StateError('Cette compétition n’appartient pas au coach connecté.');
    }
    try {
      final donnees = await _client
          .from(_nomTable)
          .update(_convertirPourModification(competition))
          .eq('id', competition.id)
          .eq('coach_id', utilisateur.id)
          .select(_colonnes)
          .single();
      return await _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (e) {
      throw Exception('Impossible de modifier la compétition : ${e.message}');
    }
  }

  @override
  Future<List<Competition>> obtenirOuvertes() async {
    _utilisateurConnecte();
    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_colonnes)
          .eq('statut', 'ouverte')
          .order('date_competition');
      return await Future.wait(donnees.map(_convertirDepuisSupabase));
    } on PostgrestException catch (e) {
      throw Exception(
        'Impossible de charger les compétitions ouvertes : ${e.message}',
      );
    }
  }

  @override
  Future<Competition> enregistrerImage(
    Competition competition,
    FichierAfficheEpreuve fichier,
  ) async {
    final extension = switch (fichier.typeMime) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw StateError('Format d’image non pris en charge.'),
    };
    final path = '${competition.id}/${_genererUuid()}.$extension';
    try {
      await _client.storage
          .from(_bucketImages)
          .uploadBinary(
            path,
            fichier.contenu,
            fileOptions: FileOptions(
              contentType: fichier.typeMime,
              upsert: false,
            ),
          );
      final ancienPath = await _client.rpc(
        'enregistrer_image_competition',
        params: {
          'p_competition_id': competition.id,
          'p_objet_path': path,
          'p_mime_type': fichier.typeMime,
          'p_taille_octets': fichier.tailleOctets,
          'p_largeur': fichier.largeurPixels,
          'p_hauteur': fichier.hauteurPixels,
        },
      ) as String?;
      if (ancienPath != null && ancienPath != path) {
        await _supprimerObjetSansMasquerSucces(ancienPath);
      }
      final url = await _client.storage
          .from(_bucketImages)
          .createSignedUrl(path, 3600);
      return competition.copierAvec(
        imageUrl: Uri.parse(url),
        dateModification: DateTime.now(),
      );
    } on StorageException catch (e) {
      await _supprimerObjetSansMasquerSucces(path);
      if (e.statusCode == '403') {
        throw StateError(
          'L’envoi temporaire est refusé par Supabase. Applique le correctif '
          'Storage 006 puis réessaie.',
        );
      }
      throw StateError(
        'Impossible d’envoyer l’image. Vérifie ta connexion puis réessaie.',
      );
    } on PostgrestException catch (e) {
      await _supprimerObjetSansMasquerSucces(path);
      throw StateError(e.message);
    } catch (_) {
      await _supprimerObjetSansMasquerSucces(path);
      rethrow;
    }
  }

  @override
  Future<Competition> supprimerImage(Competition competition) async {
    try {
      final path = await _client.rpc(
        'supprimer_image_competition',
        params: {'p_competition_id': competition.id},
      ) as String?;
      if (path != null) await _supprimerObjetSansMasquerSucces(path);
      return competition.copierAvec(
        supprimerImage: true,
        dateModification: DateTime.now(),
      );
    } on PostgrestException catch (e) {
      throw Exception('Impossible de supprimer l’image : ${e.message}');
    }
  }

  @override
  Future<void> supprimer(String id) async {
    final utilisateur = _utilisateurConnecte();
    final idNettoye = id.trim();
    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }
    try {
      await _client
          .from(_nomTable)
          .delete()
          .eq('id', idNettoye)
          .eq('coach_id', utilisateur.id);
    } on PostgrestException catch (e) {
      throw Exception('Impossible de supprimer la compétition : ${e.message}');
    }
  }

  Future<Competition> _convertirDepuisSupabase(
    Map<String, dynamic> donnees,
  ) async {
    final path = donnees['image_path'] as String?;
    Uri? imageUrl;
    if (path != null && path.isNotEmpty) {
      try {
        imageUrl = Uri.parse(
          await _client.storage.from(_bucketImages).createSignedUrl(path, 3600),
        );
      } on StorageException {
        imageUrl = null;
      }
    }
    return Competition(
      id: donnees['id'] as String,
      nom: donnees['nom'] as String,
      description: donnees['description'] as String?,
      lieu: donnees['lieu'] as String?,
      imageUrl: imageUrl,
      dateCompetition: DateTime.parse(donnees['date_competition'] as String),
      statut: _convertirStatutDepuisSupabase(donnees['statut'] as String),
      coachId: donnees['coach_id'] as String,
      dateCreation: DateTime.parse(donnees['date_creation'] as String),
      dateModification: DateTime.parse(donnees['date_modification'] as String),
      demarrageAutomatiqueMancheSuivante:
          donnees['demarrage_automatique_manche_suivante'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _convertirPourCreation(Competition competition) => {
    'nom': competition.nom,
    'description': competition.description,
    'lieu': competition.lieu,
    'date_competition': _formaterDate(competition.dateCompetition),
    'statut': _convertirStatutPourSupabase(competition.statut),
    'coach_id': competition.coachId,
    'demarrage_automatique_manche_suivante':
        competition.demarrageAutomatiqueMancheSuivante,
  };

  Map<String, dynamic> _convertirPourModification(Competition competition) => {
    'nom': competition.nom,
    'description': competition.description,
    'lieu': competition.lieu,
    'date_competition': _formaterDate(competition.dateCompetition),
    'statut': _convertirStatutPourSupabase(competition.statut),
    'demarrage_automatique_manche_suivante':
        competition.demarrageAutomatiqueMancheSuivante,
  };

  Future<void> _supprimerObjetSansMasquerSucces(String path) async {
    try {
      await _client.storage.from(_bucketImages).remove([path]);
    } catch (_) {
      // Un traitement serveur pourra nettoyer cet objet orphelin.
    }
  }

  User _utilisateurConnecte() {
    final utilisateur = _client.auth.currentUser;
    if (utilisateur == null) throw StateError('Aucun utilisateur connecté.');
    return utilisateur;
  }

  StatutCompetition _convertirStatutDepuisSupabase(String statut) =>
      switch (statut) {
        'brouillon' => StatutCompetition.brouillon,
        'ouverte' => StatutCompetition.ouverte,
        'en_cours' => StatutCompetition.enCours,
        'terminee' => StatutCompetition.terminee,
        'annulee' => StatutCompetition.annulee,
        _ => throw FormatException('Statut de compétition inconnu : $statut'),
      };

  String _convertirStatutPourSupabase(StatutCompetition statut) =>
      switch (statut) {
        StatutCompetition.brouillon => 'brouillon',
        StatutCompetition.ouverte => 'ouverte',
        StatutCompetition.enCours => 'en_cours',
        StatutCompetition.terminee => 'terminee',
        StatutCompetition.annulee => 'annulee',
      };

  String _formaterDate(DateTime date) {
    final annee = date.year.toString().padLeft(4, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');
    return '$annee-$mois-$jour';
  }

  String _genererUuid() {
    final octets = List<int>.generate(16, (_) => _aleatoire.nextInt(256));
    octets[6] = (octets[6] & 0x0f) | 0x40;
    octets[8] = (octets[8] & 0x3f) | 0x80;
    final texte = octets
        .map((octet) => octet.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${texte.substring(0, 8)}-${texte.substring(8, 12)}-'
        '${texte.substring(12, 16)}-${texte.substring(16, 20)}-'
        '${texte.substring(20)}';
  }
}
