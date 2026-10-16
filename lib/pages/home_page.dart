import 'package:flutter/material.dart';

import '../constants/sports.dart';
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
        title: const Text(AppTexts.appBarHome),
        actions: [
          IconButton(
            tooltip: AppTexts.tooltipSettings,
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
                        AppTexts.homeCardTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(AppTexts.participantsCount(count)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _homeButton(
                context,
                title: AppTexts.appBarParticipants,
                subtitle: AppTexts.homeSubtitleParticipants,
                icon: Icons.people,
                page: const ParticipantsPage(),
              ),
              _homeButton(
                context,
                title: sportNatation,
                subtitle: AppTexts.homeSubtitleNatation,
                icon: Icons.pool,
                page: const SportPage(sport: sportNatation),
              ),
              _homeButton(
                context,
                title: sportVelo,
                subtitle: AppTexts.homeSubtitleVelo,
                icon: Icons.directions_bike,
                page: const SportPage(sport: sportVelo),
              ),
              _homeButton(
                context,
                title: sportCourse,
                subtitle: AppTexts.homeSubtitleCourse,
                icon: Icons.directions_run,
                page: const SportPage(sport: sportCourse),
              ),
              _homeButton(
                context,
                title: AppTexts.appBarResults,
                subtitle: AppTexts.homeSubtitleResults,
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
