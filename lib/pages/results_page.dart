import 'package:flutter/material.dart';

import '../constants/sports.dart';
import '../services/event_data.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  List<MapEntry<String, int>> sortedScores(Map<String, int> scores) {
    final entries = scores.entries.toList();

    entries.sort((a, b) {
      final byPoints = b.value.compareTo(a.value);

      if (byPoints != 0) return byPoints;

      return a.key.compareTo(b.key);
    });

    return entries;
  }

  Widget scoreList(BuildContext context, Map<String, int> scores) {
    final entries = sortedScores(scores);

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(AppTexts.msgNoParticipantsInscribed),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(entries[i].key),
            trailing: Text(
              AppTexts.ptsSuffix(entries[i].value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = EventData.instance;

    return Scaffold(
      appBar: AppBar(title: const Text(AppTexts.appBarResults)),
      body: AnimatedBuilder(
        animation: data,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                AppTexts.titleGeneralRanking,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Card(child: scoreList(context, data.generalPoints())),
              const SizedBox(height: 20),
              Text(
                AppTexts.titleSportRankings,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              for (final sport in sports)
                Card(
                  child: ExpansionTile(
                    leading: Icon(
                      sport == sportNatation
                          ? Icons.pool
                          : sport == sportVelo
                              ? Icons.directions_bike
                              : Icons.directions_run,
                    ),
                    title: Text(sport),
                    subtitle: Text(
                      AppTexts.sportSubtitle(
                        data.config(sport).rounds,
                        data.config(sport).pointsByPosition,
                      ),
                    ),
                    children: [scoreList(context, data.pointsForSport(sport))],
                  ),
                ),
              const SizedBox(height: 16),
              const Text(AppTexts.resultsExplanation),
            ],
          );
        },
      ),
    );
  }
}
