import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sport_config.dart';
import 'database_service.dart';
import 'participant_service.dart';
import 'race_service.dart';
import 'scoring_service.dart';
import 'sport_config_service.dart';

class EventData extends ChangeNotifier {
  EventData._();

  static final EventData instance = EventData._();

  final DatabaseService databaseService = DatabaseService();
  final ParticipantService participantService = ParticipantService();
  final SportConfigService configService = SportConfigService();
  final RaceService raceService = RaceService();
  final ScoringService scoringService = ScoringService();

  List<String> get participants => participantService.participants;

  SportConfig config(String sport) => configService.config(sport);

  List<String> arrivals(String sport, int round) =>
      raceService.arrivals(sport, round);

  bool isRoundCompleted(String sport, int round) =>
      raceService.isRoundCompleted(sport, round);

  int firstUncompletedRound(String sport) =>
      raceService.firstUncompletedRound(sport, config(sport));

  Future<void> load() async {
    final user = databaseService.currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur Supabase connecté.');
    }

    final remoteData = await databaseService.fetchRemoteState(user.id);
    final localData = await databaseService.fetchLocalState();

    final legacyNames = <String>[];

    if (remoteData != null) {
      final oldParticipants = remoteData['participants'];
      if (oldParticipants is List) {
        legacyNames.addAll(oldParticipants.whereType<String>());
      }
      _restoreFromJson(remoteData);
    } else if (localData != null) {
      final oldParticipants = localData['participants'];
      if (oldParticipants is List) {
        legacyNames.addAll(oldParticipants.whereType<String>());
      }
      _restoreFromJson(localData);
    }

    final existingNames =
        await databaseService.fetchExistingParticipantNames(user.id);

    for (final name in legacyNames) {
      final cleaned = name.trim();
      if (cleaned.isNotEmpty && existingNames.add(cleaned.toLowerCase())) {
        await databaseService.insertParticipant(user.id, cleaned);
      }
    }

    final loadedParticipants =
        await databaseService.fetchAllParticipants(user.id);
    participantService.setParticipants(loadedParticipants);

    await _save();
    notifyListeners();
  }

  void _restoreFromJson(Map<String, dynamic> json) {
    participantService.setParticipants(
      (json['participants'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
    configService.restoreFromJson(json['configs'] as Map<String, dynamic>?);
    raceService.restoreFromJson(
      savedArrivals: json['arrivals'] as Map<String, dynamic>?,
      savedCompleted: json['completedRounds'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> _toJson() {
    return {
      'participants': participants,
      'configs': configService.toJson(),
      'arrivals': raceService.arrivalsToJson(),
      'completedRounds': raceService.completedRoundsToJson(),
    };
  }

  Future<void> _save() async {
    final user = databaseService.currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur Supabase connecté.');
    }
    await databaseService.saveState(user.id, _toJson());
  }

  Future<bool> addParticipant(String name) async {
    final success =
        await participantService.addParticipant(databaseService, name);
    if (success) {
      await _save();
      notifyListeners();
    }
    return success;
  }

  Future<void> removeParticipant(String name) async {
    final success =
        await participantService.removeParticipant(databaseService, name);
    if (success) {
      raceService.removeParticipantFromArrivals(name);
      await _save();
      notifyListeners();
    }
  }

  Future<void> updateConfig(
    String sport, {
    required int rounds,
    required int durationSeconds,
    required int restSeconds,
  }) async {
    configService.updateConfig(
      sport,
      rounds: rounds,
      durationSeconds: durationSeconds,
      restSeconds: restSeconds,
    );
    await _save();
    notifyListeners();
  }

  Future<void> addArrival(String sport, int round, String participant) async {
    final success = raceService.addArrival(
      sport,
      round,
      participant,
      config(sport),
      participants,
    );
    if (success) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> finishRound(String sport, int round) async {
    final success = raceService.finishRound(sport, round, config(sport));
    if (success) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> resetSport(String sport) async {
    raceService.resetSport(sport);
    await _save();
    notifyListeners();
  }

  Future<void> resetAll() async {
    participantService.clear();
    raceService.resetAll();
    await _save();
    notifyListeners();
  }

  Map<String, int> pointsForSport(String sport) {
    return scoringService.pointsForSport(sport, participants, raceService);
  }

  Map<String, int> generalPoints() {
    return scoringService.generalPoints(participants, raceService);
  }
}
