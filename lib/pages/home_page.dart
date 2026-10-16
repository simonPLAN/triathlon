import 'package:flutter/material.dart';

import '../services/event_data.dart';
import 'participants_page.dart';
import 'results_page.dart';
import 'settings_page.dart';
import 'sport_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du triathlon'),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: EventData.instance,
        builder: (context, _) {
          final count = EventData.instance.participants.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 56),
                      const SizedBox(height: 8),
                      Text(
                        'Épreuve de triathlon',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('$count participant(s) inscrit(s)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _homeButton(
                context,
                title: 'Participants',
                subtitle: 'Ajouter ou supprimer des participants',
                icon: Icons.people,
                page: const ParticipantsPage(),
              ),
              _homeButton(
                context,
                title: 'Natation',
                subtitle: 'Configurer et lancer la natation',
                icon: Icons.pool,
                page: const SportPage(sport: 'Natation'),
              ),
              _homeButton(
                context,
                title: 'Vélo',
                subtitle: 'Configurer et lancer le vélo',
                icon: Icons.directions_bike,
                page: const SportPage(sport: 'Vélo'),
              ),
              _homeButton(
                context,
                title: 'Course à pied',
                subtitle: 'Configurer et lancer la course à pied',
                icon: Icons.directions_run,
                page: const SportPage(sport: 'Course à pied'),
              ),
              _homeButton(
                context,
                title: 'Résultats et classements',
                subtitle: 'Classements par sport et général',
                icon: Icons.leaderboard,
                page: const ResultsPage(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _homeButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget page,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page));
        },
      ),
    );
  }
}
