import '../constants/sports.dart';
import 'race_service.dart';

class ScoringService {
  Map<String, int> pointsForSport(
    String sport,
    List<String> participants,
    RaceService raceService,
  ) {
    final scores = <String, int>{
      for (final participant in participants) participant: 0,
    };

    final arrivalsMap = raceService.allArrivalsForSport(sport);

    for (final entry in arrivalsMap.entries) {
      final arrivalList = entry.value;

      for (int i = 0; i < arrivalList.length; i++) {
        final participant = arrivalList[i];

        final points =
            (participants.length - i).clamp(0, participants.length).toInt();

        scores[participant] = (scores[participant] ?? 0) + points;
      }
    }

    return scores;
  }

  Map<String, int> generalPoints(
    List<String> participants,
    RaceService raceService,
  ) {
    final scores = <String, int>{
      for (final participant in participants) participant: 0,
    };

    for (final sport in sports) {
      final sportScores = pointsForSport(sport, participants, raceService);

      for (final entry in sportScores.entries) {
        scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
      }
    }

    return scores;
  }
}
