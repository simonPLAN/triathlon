import '../constants/sports.dart';
import '../models/sport_config.dart';

class RaceService {
  final Map<String, Map<int, List<String>>> _arrivals = {
    for (final sport in sports) sport: <int, List<String>>{},
  };

  final Map<String, Set<int>> _completedRounds = {
    for (final sport in sports) sport: <int>{},
  };

  Map<int, List<String>> _sportArrivals(String sport) {
    return _arrivals.putIfAbsent(sport, () => <int, List<String>>{});
  }

  Set<int> _sportCompletedRounds(String sport) {
    return _completedRounds.putIfAbsent(sport, () => <int>{});
  }

  List<String> arrivals(String sport, int round) {
    return List<String>.unmodifiable(
      _sportArrivals(sport)[round] ?? <String>[],
    );
  }

  Map<int, List<String>> allArrivalsForSport(String sport) {
    return _sportArrivals(sport);
  }

  bool isRoundCompleted(String sport, int round) {
    return _sportCompletedRounds(sport).contains(round);
  }

  int firstUncompletedRound(String sport, SportConfig config) {
    for (int i = 0; i < config.rounds; i++) {
      if (!isRoundCompleted(sport, i)) {
        return i;
      }
    }
    return config.rounds;
  }

  bool addArrival(
    String sport,
    int round,
    String participant,
    SportConfig config,
    List<String> participants,
  ) {
    if (round < 0 || round >= config.rounds) return false;
    if (!participants.contains(participant)) return false;
    if (isRoundCompleted(sport, round)) return false;

    final list = _sportArrivals(sport).putIfAbsent(round, () => <String>[]);
    if (list.contains(participant)) return false;

    list.add(participant);
    return true;
  }

  bool undoLastArrival(String sport, int round) {
    if (isRoundCompleted(sport, round)) return false;

    final list = _sportArrivals(sport)[round];
    if (list == null || list.isEmpty) return false;

    list.removeLast();
    return true;
  }

  bool removeArrival(String sport, int round, String participant) {
    if (isRoundCompleted(sport, round)) return false;

    final list = _sportArrivals(sport)[round];
    if (list == null) return false;

    return list.remove(participant);
  }

  bool moveArrival(String sport, int round, int oldIndex, int newIndex) {
    if (isRoundCompleted(sport, round)) return false;

    final list = _sportArrivals(sport)[round];
    if (list == null ||
        oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex >= list.length) {
      return false;
    }

    final participant = list.removeAt(oldIndex);
    list.insert(newIndex, participant);
    return true;
  }

  bool finishRound(String sport, int round, SportConfig config) {
    if (round < 0 || round >= config.rounds) return false;

    _sportCompletedRounds(sport).add(round);
    return true;
  }

  void resetSport(String sport) {
    _sportArrivals(sport).clear();
    _sportCompletedRounds(sport).clear();
  }

  void resetAll() {
    for (final sport in sports) {
      _sportArrivals(sport).clear();
      _sportCompletedRounds(sport).clear();
    }
  }

  void removeParticipantFromArrivals(String name) {
    for (final sport in sports) {
      for (final list in _sportArrivals(sport).values) {
        list.remove(name);
      }
    }
  }

  void restoreFromJson({
    required Map<String, dynamic>? savedArrivals,
    required Map<String, dynamic>? savedCompleted,
  }) {
    for (final sport in sports) {
      _sportArrivals(sport).clear();
      _sportCompletedRounds(sport).clear();
    }

    if (savedArrivals != null) {
      for (final sport in sports) {
        final sportData = savedArrivals[sport];
        if (sportData is Map) {
          sportData.forEach((key, value) {
            final round = int.tryParse(key.toString());
            if (round != null && value is List) {
              _sportArrivals(sport)[round] = value
                  .map((e) => e.toString())
                  .toList();
            }
          });
        }
      }
    }

    if (savedCompleted != null) {
      for (final sport in sports) {
        final rounds = savedCompleted[sport];
        if (rounds is List) {
          for (final round in rounds) {
            final value = int.tryParse(round.toString());
            if (value != null) {
              _sportCompletedRounds(sport).add(value);
            }
          }
        }
      }
    }
  }

  Map<String, dynamic> arrivalsToJson() {
    final savedArrivals = <String, dynamic>{};

    for (final sport in sports) {
      savedArrivals[sport] = {
        for (final entry in _sportArrivals(sport).entries)
          entry.key.toString(): entry.value,
      };
    }

    return savedArrivals;
  }

  Map<String, dynamic> completedRoundsToJson() {
    final savedCompleted = <String, dynamic>{};

    for (final sport in sports) {
      savedCompleted[sport] = _sportCompletedRounds(sport).toList();
    }

    return savedCompleted;
  }
}
