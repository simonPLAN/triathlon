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
        child: Text('Aucun participant inscrit.'),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(entries[i].key),
            trailing: Text(
              '${entries[i].value} pts',
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
      appBar: AppBar(title: const Text('Résultats et classements')),
      body: AnimatedBuilder(
        animation: data,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Classement général',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Card(child: scoreList(context, data.generalPoints())),
              const SizedBox(height: 20),
              Text(
                'Classements par sport',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              for (final sport in sports)
                Card(
                  child: ExpansionTile(
                    leading: Icon(
                      sport == 'Natation'
                          ? Icons.pool
                          : sport == 'Vélo'
                              ? Icons.directions_bike
                              : Icons.directions_run,
                    ),
                    title: Text(sport),
                    subtitle: Text(
                      '${data.config(sport).rounds} manches • Barème : ${data.config(sport).pointsByPosition.join("-")} pts',
                    ),
                    children: [scoreList(context, data.pointsForSport(sport))],
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Les points dépendent de l’ordre des arrivées '
                'dans chaque manche selon le barème configuré. '
                'Le classement général additionne les points des trois sports.',
              ),
            ],
          );
        },
      ),
    );
  }
}
