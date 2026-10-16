import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/models/sport_config.dart';
import 'package:triathlon/services/race_service.dart';
import 'package:triathlon/services/scoring_service.dart';

void main() {
  group('ScoringService with custom points', () {
    late RaceService raceService;
    late ScoringService scoringService;

    setUp(() {
      raceService = RaceService();
      scoringService = ScoringService();
    });

    test('assigns points according to custom pointsByPosition', () {
      final config = SportConfig(
        rounds: 1,
        durationSeconds: 180,
        restSeconds: 90,
        pointsByPosition: [5, 4, 3, 2, 1],
      );

      final participants = ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank'];

      raceService.addArrival('Natation', 0, 'Alice', config, participants);
      raceService.addArrival('Natation', 0, 'Bob', config, participants);
      raceService.addArrival('Natation', 0, 'Charlie', config, participants);
      raceService.addArrival('Natation', 0, 'David', config, participants);
      raceService.addArrival('Natation', 0, 'Eve', config, participants);
      raceService.addArrival('Natation', 0, 'Frank', config, participants);

      final scores = scoringService.pointsForSport(
        'Natation',
        participants,
        raceService,
        config,
      );

      expect(scores['Alice'], 5); // 1st
      expect(scores['Bob'], 4); // 2nd
      expect(scores['Charlie'], 3); // 3rd
      expect(scores['David'], 2); // 4th
      expect(scores['Eve'], 1); // 5th
      expect(scores['Frank'], 0); // 6th (beyond configured positions)
    });

    test('SportConfig toJson and fromJson preserve pointsByPosition', () {
      final config = SportConfig(
        rounds: 3,
        durationSeconds: 120,
        restSeconds: 60,
        pointsByPosition: [10, 8, 6, 4, 2],
      );

      final json = config.toJson();
      final restored = SportConfig.fromJson(json);

      expect(restored.rounds, 3);
      expect(restored.durationSeconds, 120);
      expect(restored.restSeconds, 60);
      expect(restored.pointsByPosition, [10, 8, 6, 4, 2]);
    });
  });
}
