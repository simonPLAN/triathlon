import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/manche.dart';
import '../../../domain/entities/statut_manche.dart';
import '../../../domain/ports/manche_repository.dart';

class MancheRepositorySupabase implements MancheRepository {
  MancheRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const String _nomTable = 'manches';

  static const String _colonnes = '''
    id,
    epreuve_id,
    numero,
    statut,
    heure_depart,
    heure_premiere_arrivee,
    heure_fin_delai,
    resultats_publies,
    revision_resultats,
    revision_validation_resultats,
    participants_definis,
    duree_limite_secondes,
    participants_manche(athlete_id,ordre_depart),
    date_creation,
    date_modification
  ''';

  @override
  Future<List<Manche>> obtenirParEpreuve(String epreuveId) async {
    final idNettoye = epreuveId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_colonnes)
          .eq('epreuve_id', idNettoye)
          .order('numero', ascending: true);

      return donnees
          .map<Manche>(_convertirDepuisSupabase)
          .toList(growable: false);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de charger les manches : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<Manche?> obtenirParId(String id) async {
    final idNettoye = id.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    try {
      final donnees = await _client
          .from(_nomTable)
          .select(_colonnes)
          .eq('id', idNettoye)
          .maybeSingle();

      if (donnees == null) {
        return null;
      }

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de récupérer la manche : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<List<Manche>> creerPlusieurs(List<Manche> manches) async {
    if (manches.isEmpty) {
      throw ArgumentError('La liste des manches ne peut pas être vide.');
    }

    final epreuveId = manches.first.epreuveId.trim();

    if (epreuveId.isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    final toutesMemeEpreuve = manches.every(
      (manche) => manche.epreuveId == epreuveId,
    );

    if (!toutesMemeEpreuve) {
      throw ArgumentError(
        'Toutes les manches doivent appartenir '
        'à la même épreuve.',
      );
    }

    try {
      final valeurs = manches
          .map(_convertirPourCreation)
          .toList(growable: false);

      final donnees = await _client
          .from(_nomTable)
          .insert(valeurs)
          .select(_colonnes);

      final manchesCreees = donnees
          .map<Manche>(_convertirDepuisSupabase)
          .toList(growable: false);

      manchesCreees.sort((mancheA, mancheB) {
        return mancheA.numero.compareTo(mancheB.numero);
      });

      return List.unmodifiable(manchesCreees);
    } on PostgrestException catch (exception) {
      throw Exception(_messageErreurCreation(exception));
    }
  }

  @override
  Future<Manche> modifier(Manche manche) async {
    final idNettoye = manche.id.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de la manche est obligatoire.');
    }

    try {
      if (manche.resultatsPublies) {
        final donnees = await _client.rpc(
          'publier_resultats_manche_verifies',
          params: {
            'p_manche_id': manche.id,
            'p_revision': manche.revisionResultats,
          },
        );
        return _convertirDepuisSupabase(
          Map<String, dynamic>.from(donnees as Map),
        ).copierAvec(participantsAthleteIds: manche.participantsAthleteIds);
      }
      final donnees = await _client
          .from(_nomTable)
          .update(_convertirPourModification(manche))
          .eq('id', idNettoye)
          .select(_colonnes)
          .single();

      return _convertirDepuisSupabase(donnees);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de modifier la manche : '
        '${exception.message}',
      );
    }
  }

  @override
  Future<void> supprimerParEpreuve(String epreuveId) async {
    final idNettoye = epreuveId.trim();

    if (idNettoye.isEmpty) {
      throw ArgumentError('L’identifiant de l’épreuve est obligatoire.');
    }

    try {
      await _client.from(_nomTable).delete().eq('epreuve_id', idNettoye);
    } on PostgrestException catch (exception) {
      throw Exception(
        'Impossible de supprimer les manches : '
        '${exception.message}',
      );
    }
  }

  Manche _convertirDepuisSupabase(Map<String, dynamic> donnees) {
    return Manche(
      id: donnees['id'] as String,
      epreuveId: donnees['epreuve_id'] as String,
      numero: donnees['numero'] as int,
      statut: _convertirStatutDepuisSupabase(donnees['statut'] as String),
      heureDepart: _convertirDateFacultative(donnees['heure_depart']),
      heurePremiereArrivee: _convertirDateFacultative(
        donnees['heure_premiere_arrivee'],
      ),
      heureFinDelai: _convertirDateFacultative(donnees['heure_fin_delai']),
      resultatsPublies: donnees['resultats_publies'] as bool,
      revisionResultats: (donnees['revision_resultats'] as num?)?.toInt() ?? 0,
      validationRequise: donnees.containsKey('revision_validation_resultats'),
      revisionValidationResultats: (donnees['revision_validation_resultats'] as num?)?.toInt(),
      participantsDefinis: donnees['participants_definis'] == true,
      participantsAthleteIds: _participants(donnees),
      dureeLimiteSecondes: (donnees['duree_limite_secondes'] as num?)?.toInt(),
      dateCreation: DateTime.parse(donnees['date_creation'] as String),
      dateModification: DateTime.parse(donnees['date_modification'] as String),
    );
  }

  Map<String, dynamic> _convertirPourCreation(Manche manche) {
    return {
      'epreuve_id': manche.epreuveId,
      'numero': manche.numero,
      'statut': _convertirStatutPourSupabase(manche.statut),
      'heure_depart': manche.heureDepart?.toUtc().toIso8601String(),
      'heure_premiere_arrivee': manche.heurePremiereArrivee
          ?.toUtc()
          .toIso8601String(),
      'heure_fin_delai': manche.heureFinDelai?.toUtc().toIso8601String(),
      'resultats_publies': manche.resultatsPublies,
    };
  }

  Map<String, dynamic> _convertirPourModification(Manche manche) {
    return {
      'statut': _convertirStatutPourSupabase(manche.statut),
      'heure_depart': manche.heureDepart?.toUtc().toIso8601String(),
      'heure_premiere_arrivee': manche.heurePremiereArrivee
          ?.toUtc()
          .toIso8601String(),
      'heure_fin_delai': manche.heureFinDelai?.toUtc().toIso8601String(),
      'resultats_publies': manche.resultatsPublies,
    };
  }

  List<String> _participants(Map<String, dynamic> donnees) {
    final lignes = (donnees['participants_manche'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();
    lignes.sort((a, b) => (a['ordre_depart'] as num).compareTo(b['ordre_depart'] as num));
    return List.unmodifiable(lignes.map((e) => e['athlete_id'] as String));
  }

  DateTime? _convertirDateFacultative(dynamic valeur) {
    if (valeur == null) {
      return null;
    }

    return DateTime.parse(valeur as String).toLocal();
  }

  StatutManche _convertirStatutDepuisSupabase(String statut) {
    switch (statut) {
      case 'a_venir':
        return StatutManche.aVenir;

      case 'en_cours':
        return StatutManche.enCours;

      case 'terminee':
        return StatutManche.terminee;

      case 'annulee':
        return StatutManche.annulee;

      default:
        throw FormatException('Statut de manche inconnu : $statut');
    }
  }

  String _convertirStatutPourSupabase(StatutManche statut) {
    switch (statut) {
      case StatutManche.aVenir:
        return 'a_venir';

      case StatutManche.enCours:
        return 'en_cours';

      case StatutManche.terminee:
        return 'terminee';

      case StatutManche.annulee:
        return 'annulee';
    }
  }

  String _messageErreurCreation(PostgrestException exception) {
    if (exception.code == '23505') {
      return 'Les manches de cette épreuve '
          'ont déjà été générées.';
    }

    if (exception.code == '23514') {
      return 'Les données des manches sont invalides.';
    }

    return 'Impossible de générer les manches : '
        '${exception.message}';
  }
}
