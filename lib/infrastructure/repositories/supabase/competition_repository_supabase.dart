import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../../domain/ports/competition_repository.dart';

class CompetitionRepositorySupabase implements CompetitionRepository {
  CompetitionRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const String _nomTable = 'competitions';

  @override
  Future<List<Competition>> obtenirToutes() async {
    final utilisateur = _utilisateurConnecte();

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(
            'id, nom, description, lieu, date_competition, '
            'statut, coach_id, date_creation, date_modification',
          )
          .eq('coach_id', utilisateur.id)
          .order('date_competition', ascending: true);

      return donnees
          .map<Competition>(_convertirDepuisSupabase)
          .toList(growable: false);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de charger les compétitions : '
        '${exception.message}',
      );
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
          .select(
            'id, nom, description, lieu, date_competition, '
            'statut, coach_id, date_creation, date_modification',
          )
          .eq('id', idNettoye)
          .eq('coach_id', utilisateur.id)
          .maybeSingle();

      if (donnees == null) {
        return null;
      }

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de récupérer la compétition : '
        '${exception.message}',
      );
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
          .select(
            'id, nom, description, lieu, date_competition, '
            'statut, coach_id, date_creation, date_modification',
          )
          .single();

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de créer la compétition : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<Competition> modifier(Competition competition) async {
    final utilisateur = _utilisateurConnecte();

    if (competition.id.trim().isEmpty) {
      throw ArgumentError('L’identifiant de la compétition est obligatoire.');
    }

    if (competition.coachId != utilisateur.id) {
      throw StateError(
        'Cette compétition n’appartient pas '
        'au coach connecté.',
      );
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .update(_convertirPourModification(competition))
          .eq('id', competition.id)
          .eq('coach_id', utilisateur.id)
          .select(
            'id, nom, description, lieu, date_competition, '
            'statut, coach_id, date_creation, date_modification',
          )
          .single();

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de modifier la compétition : '
        '${exception.message}',
      );
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
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de supprimer la compétition : '
        '${exception.message}',
      );
    }
  }

  User _utilisateurConnecte() {
    final utilisateur = _client.auth.currentUser;

    if (utilisateur == null) {
      throw StateError('Aucun utilisateur connecté.');
    }

    return utilisateur;
  }

  Competition _convertirDepuisSupabase(Map<String, dynamic> donnees) {
    return Competition(
      id: donnees['id'] as String,
      nom: donnees['nom'] as String,
      description: donnees['description'] as String?,
      lieu: donnees['lieu'] as String?,
      dateCompetition: DateTime.parse(donnees['date_competition'] as String),
      statut: _convertirStatutDepuisSupabase(donnees['statut'] as String),
      coachId: donnees['coach_id'] as String,
      dateCreation: DateTime.parse(donnees['date_creation'] as String),
      dateModification: DateTime.parse(donnees['date_modification'] as String),
    );
  }

  Map<String, dynamic> _convertirPourCreation(Competition competition) {
    return {
      'nom': competition.nom,
      'description': competition.description,
      'lieu': competition.lieu,
      'date_competition': _formaterDate(competition.dateCompetition),
      'statut': _convertirStatutPourSupabase(competition.statut),
      'coach_id': competition.coachId,
    };
  }

  Map<String, dynamic> _convertirPourModification(Competition competition) {
    return {
      'nom': competition.nom,
      'description': competition.description,
      'lieu': competition.lieu,
      'date_competition': _formaterDate(competition.dateCompetition),
      'statut': _convertirStatutPourSupabase(competition.statut),
    };
  }

  StatutCompetition _convertirStatutDepuisSupabase(String statut) {
    switch (statut) {
      case 'brouillon':
        return StatutCompetition.brouillon;
      case 'ouverte':
        return StatutCompetition.ouverte;
      case 'en_cours':
        return StatutCompetition.enCours;
      case 'terminee':
        return StatutCompetition.terminee;
      case 'annulee':
        return StatutCompetition.annulee;
      default:
        throw FormatException('Statut de compétition inconnu : $statut');
    }
  }

  String _convertirStatutPourSupabase(StatutCompetition statut) {
    switch (statut) {
      case StatutCompetition.brouillon:
        return 'brouillon';
      case StatutCompetition.ouverte:
        return 'ouverte';
      case StatutCompetition.enCours:
        return 'en_cours';
      case StatutCompetition.terminee:
        return 'terminee';
      case StatutCompetition.annulee:
        return 'annulee';
    }
  }

  String _formaterDate(DateTime date) {
    final annee = date.year.toString().padLeft(4, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final jour = date.day.toString().padLeft(2, '0');

    return '$annee-$mois-$jour';
  }
}
