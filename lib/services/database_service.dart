import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/sports.dart';

class DatabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

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

  Future<void> insertParticipant(String userId, String name) async {
    await _client.from('participants').insert({'user_id': userId, 'nom': name});
  }

  Future<void> deleteParticipant(String userId, String name) async {
    await _client
        .from('participants')
        .delete()
        .eq('user_id', userId)
        .eq('nom', name);
  }

  Future<List<String>> fetchAllParticipants(String userId) async {
    final participantRows = await _client
        .from('participants')
        .select('nom')
        .eq('user_id', userId)
        .order('created_at');

    return participantRows.map((row) => row['nom'] as String).toList();
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
