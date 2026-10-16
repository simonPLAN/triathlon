import 'package:flutter/material.dart';

import '../constants/sports.dart';
import '../services/event_data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final EventData data = EventData.instance;

  final Map<String, TextEditingController> roundsControllers = {};
  final Map<String, TextEditingController> durationControllers = {};
  final Map<String, TextEditingController> restControllers = {};

  TextEditingController _controllerFor(
    Map<String, TextEditingController> controllers,
    String sport,
    int initialValue,
  ) {
    return controllers.putIfAbsent(
      sport,
      () => TextEditingController(text: initialValue.toString()),
    );
  }

  @override
  void initState() {
    super.initState();

    for (final sport in sports) {
      final config = data.config(sport);

      _controllerFor(roundsControllers, sport, config.rounds);

      _controllerFor(durationControllers, sport, config.durationSeconds);

      _controllerFor(restControllers, sport, config.restSeconds);
    }
  }

  @override
  void dispose() {
    for (final controller in roundsControllers.values) {
      controller.dispose();
    }

    for (final controller in durationControllers.values) {
      controller.dispose();
    }

    for (final controller in restControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  int? _readValue(
    Map<String, TextEditingController> controllers,
    String sport,
    int initialValue,
  ) {
    final controller = _controllerFor(controllers, sport, initialValue);

    return int.tryParse(controller.text.trim());
  }

  Future<void> saveSettings() async {
    final Map<String, int> roundsValues = {};
    final Map<String, int> durationValues = {};
    final Map<String, int> restValues = {};

    for (final sport in sports) {
      final config = data.config(sport);

      final rounds = _readValue(roundsControllers, sport, config.rounds);

      final duration = _readValue(
        durationControllers,
        sport,
        config.durationSeconds,
      );

      final rest = _readValue(restControllers, sport, config.restSeconds);

      if (rounds == null ||
          rounds < 1 ||
          rounds > 100 ||
          duration == null ||
          duration < 1 ||
          duration > 86400 ||
          rest == null ||
          rest < 0 ||
          rest > 86400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vérifie les valeurs : manches entre 1 et 100, '
              'durée entre 1 et 86400 secondes et repos '
              'entre 0 et 86400 secondes.',
            ),
          ),
        );

        return;
      }

      roundsValues[sport] = rounds;
      durationValues[sport] = duration;
      restValues[sport] = rest;
    }

    try {
      for (final sport in sports) {
        await data.updateConfig(
          sport,
          rounds: roundsValues[sport]!,
          durationSeconds: durationValues[sport]!,
          restSeconds: restValues[sport]!,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réglages enregistrés avec succès !')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
      );
    }
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages des épreuves')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Configure chaque épreuve indépendamment. '
            'Le compte à rebours démarre à la première arrivée.',
          ),
          const SizedBox(height: 16),
          for (final sport in sports)
            Builder(
              key: ValueKey('settings_$sport'),
              builder: (context) {
                final config = data.config(sport);

                final roundsController = _controllerFor(
                  roundsControllers,
                  sport,
                  config.rounds,
                );

                final durationController = _controllerFor(
                  durationControllers,
                  sport,
                  config.durationSeconds,
                );

                final restController = _controllerFor(
                  restControllers,
                  sport,
                  config.restSeconds,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sport,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _numberField(
                          label: 'Nombre de manches',
                          controller: roundsController,
                        ),
                        const SizedBox(height: 12),
                        _numberField(
                          label: 'Compte à rebours (secondes)',
                          controller: durationController,
                        ),
                        const SizedBox(height: 12),
                        _numberField(
                          label: 'Repos entre les manches (secondes)',
                          controller: restController,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer les réglages'),
          ),
        ],
      ),
    );
  }
}
