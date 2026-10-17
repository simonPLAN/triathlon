import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/sports.dart';
import '../models/participant.dart';

class DatabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  dynamic _formatCoef(double coefficient) {
    if (coefficient == coefficient.toInt()) {
      return coefficient.toInt();
    }
    return coefficient;
  }

  Future<Map<String, dynamic>?> fetchRemoteState(String userId) async {
    final remoteRow = await _client
        .from('triathlon_state')
        .select('data')
        .eq('user_id', userId)
        .maybeSingle();

    if (remoteRow != null && remoteRow['data'] is Map) {
      return Map<String, dynamic>.from(remoteRow['data'] as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final localRaw = prefs.getString(storageKey);

    if (localRaw != null && localRaw.isNotEmpty) {
      final decoded = jsonDecode(localRaw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return null;
  }

  Future<Set<String>> fetchExistingParticipantNames(String userId) async {
    final existingRows = await _client
        .from('participants')
        .select('nom')
        .eq('user_id', userId);

    return {
      for (final row in existingRows) (row['nom'] as String).toLowerCase(),
    };
  }

  Future<void> insertParticipant(
    String userId,
    String name,
    double coefficient,
  ) async {
    final coefVal = _formatCoef(coefficient);
    try {
      await _client.from('participants').insert({
        'user_id': userId,
        'nom': name,
        'coefficient': coefVal,
      });
    } catch (e) {
      debugPrint('SUPABASE insertParticipant error: $e');
      try {
        await _client.from('participants').insert({
          'user_id': userId,
          'nom': name,
        });
      } catch (e2) {
        debugPrint('SUPABASE insertParticipant fallback error: $e2');
      }
    }
  }

  Future<void> updateParticipantCoefficient(
    String userId,
    String name,
    double coefficient,
  ) async {
    final coefVal = _formatCoef(coefficient);
    try {
      await _client
          .from('participants')
          .update({'coefficient': coefVal})
          .eq('user_id', userId)
          .eq('nom', name);
    } catch (e) {
      debugPrint('SUPABASE updateParticipantCoefficient error: $e');
    }
  }

  Future<void> deleteParticipant(String userId, String name) async {
    await _client
        .from('participants')
        .delete()
        .eq('user_id', userId)
        .eq('nom', name);
  }

  Future<List<Participant>> fetchAllParticipants(String userId) async {
    try {
      final participantRows = await _client
          .from('participants')
          .select('nom, coefficient')
          .eq('user_id', userId)
          .order('created_at');

      return participantRows.map((row) {
        final name = row['nom'] as String;
        final coef = (row['coefficient'] as num?)?.toDouble() ?? 1.0;
        return Participant(name: name, coefficient: coef);
      }).toList();
    } catch (e) {
      debugPrint('SUPABASE fetchAllParticipants error: $e');
      final participantRows = await _client
          .from('participants')
          .select('nom')
          .eq('user_id', userId)
          .order('created_at');

      return participantRows.map((row) {
        final name = row['nom'] as String;
        return Participant(name: name, coefficient: 1.0);
      }).toList();
    }
  }

  Future<void> saveState(String userId, Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(json));

      final cloudJson = Map<String, dynamic>.from(json)..remove('participants');

      await _client.from('triathlon_state').upsert({
        'user_id': userId,
        'data': cloudJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('SUPABASE : sauvegarde réussie pour $userId');
    } catch (e, stackTrace) {
      debugPrint('ERREUR SAUVEGARDE : $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
