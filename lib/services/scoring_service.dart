import '../constants/sports.dart';
import '../models/sport_config.dart';
import 'race_service.dart';
import 'sport_config_service.dart';

class ScoringService {
  Map<String, int> pointsForSport(
    String sport,
    List<String> participants,
    RaceService raceService,
    SportConfig config,
  ) {
    final scores = <String, int>{
      for (final participant in participants) participant: 0,
    };

    final arrivalsMap = raceService.allArrivalsForSport(sport);
    final pointsByPosition = config.pointsByPosition;

    for (final entry in arrivalsMap.entries) {
      final arrivalList = entry.value;

      for (int i = 0; i < arrivalList.length; i++) {
        final participant = arrivalList[i];

        final int points;
        if (pointsByPosition.isNotEmpty) {
          points = i < pointsByPosition.length ? pointsByPosition[i] : 0;
        } else {
          points =
              (participants.length - i).clamp(0, participants.length).toInt();
        }

        scores[participant] = (scores[participant] ?? 0) + points;
      }
    }

    return scores;
  }

  Map<String, int> generalPoints(
    List<String> participants,
    RaceService raceService,
    SportConfigService configService,
  ) {
    final scores = <String, int>{
      for (final participant in participants) participant: 0,
    };

    for (final sport in sports) {
      final sportConfig = configService.config(sport);
      final sportScores =
          pointsForSport(sport, participants, raceService, sportConfig);

      for (final entry in sportScores.entries) {
        scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
      }
    }

    return scores;
  }
}
