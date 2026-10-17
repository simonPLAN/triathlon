import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon/models/participant.dart';
import 'package:triathlon/models/sport_config.dart';
import 'package:triathlon/services/race_service.dart';
import 'package:triathlon/services/scoring_service.dart';

void main() {
  group('ScoringService with custom points and coefficients', () {
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

    test('applies coefficient multiplier to points earned in each round', () {
      final config = SportConfig(
        rounds: 2,
        durationSeconds: 180,
        restSeconds: 90,
        pointsByPosition: [10, 8, 6],
      );

      final participants = ['Alice', 'Bob', 'Charlie'];
      final coefficients = {
        'Alice': 1.5, // 10 * 1.5 = 15 pts per round
        'Bob': 1.0, // 8 * 1.0 = 8 pts per round
        'Charlie': 2.0, // 6 * 2.0 = 12 pts per round
      };

      // Round 0
      raceService.addArrival('Natation', 0, 'Alice', config, participants);
      raceService.addArrival('Natation', 0, 'Bob', config, participants);
      raceService.addArrival('Natation', 0, 'Charlie', config, participants);

      // Round 1
      raceService.addArrival('Natation', 1, 'Alice', config, participants);
      raceService.addArrival('Natation', 1, 'Bob', config, participants);
      raceService.addArrival('Natation', 1, 'Charlie', config, participants);

      final scores = scoringService.pointsForSport(
        'Natation',
        participants,
        raceService,
        config,
        coefficients: coefficients,
      );

      // Alice: 15 + 15 = 30
      expect(scores['Alice'], 30);
      // Bob: 8 + 8 = 16
      expect(scores['Bob'], 16);
      // Charlie: 12 + 12 = 24
      expect(scores['Charlie'], 24);
    });

    test('Participant serialization and deserialization works', () {
      const p1 = Participant(name: 'Alice', coefficient: 1.5);
      final json = p1.toJson();

      expect(json['name'], 'Alice');
      expect(json['coefficient'], 1.5);

      final restored = Participant.fromJson(json);
      expect(restored.name, 'Alice');
      expect(restored.coefficient, 1.5);

      // Legacy string format
      final legacy = Participant.fromJson('Bob');
      expect(legacy.name, 'Bob');
      expect(legacy.coefficient, 1.0);
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
