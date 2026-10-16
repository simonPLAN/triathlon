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
  final Map<String, List<TextEditingController>> pointsControllers = {};

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

      pointsControllers[sport] = config.pointsByPosition
          .map((p) => TextEditingController(text: p.toString()))
          .toList();
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

    for (final list in pointsControllers.values) {
      for (final controller in list) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  String positionLabel(int index) {
    final rank = index + 1;
    if (rank == 1) return '1er';
    return '$rankème';
  }

  void _addPosition(String sport) {
    setState(() {
      final list = pointsControllers[sport] ?? [];
      int nextVal = 0;
      if (list.isNotEmpty) {
        final lastVal = int.tryParse(list.last.text.trim()) ?? 1;
        nextVal = (lastVal - 1).clamp(0, 999);
      }
      list.add(TextEditingController(text: nextVal.toString()));
      pointsControllers[sport] = list;
    });
  }

  void _removePosition(String sport) {
    final list = pointsControllers[sport];
    if (list != null && list.length > 1) {
      setState(() {
        final removed = list.removeLast();
        removed.dispose();
      });
    }
  }

  void _applyPointsToAllSports(String sourceSport) {
    final sourceList = pointsControllers[sourceSport];
    if (sourceList == null || sourceList.isEmpty) return;

    final sourceValues = sourceList.map((c) => c.text).toList();

    setState(() {
      for (final sport in sports) {
        if (sport == sourceSport) continue;

        final oldList = pointsControllers[sport];
        if (oldList != null) {
          for (final c in oldList) {
            c.dispose();
          }
        }

        pointsControllers[sport] = sourceValues
            .map((val) => TextEditingController(text: val))
            .toList();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppTexts.msgPointsCopied),
      ),
    );
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
    final Map<String, List<int>> pointsValues = {};

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
          rounds < minRounds ||
          rounds > maxRounds ||
          duration == null ||
          duration < minDurationSeconds ||
          duration > maxDurationSeconds ||
          rest == null ||
          rest < minRestSeconds ||
          rest > maxRestSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppTexts.msgInvalidSettingsValues),
          ),
        );

        return;
      }

      final pControllers = pointsControllers[sport] ?? [];
      if (pControllers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTexts.minPointsPositionError(sport)),
          ),
        );
        return;
      }

      final sportPoints = <int>[];
      for (int i = 0; i < pControllers.length; i++) {
        final val = int.tryParse(pControllers[i].text.trim());
        if (val == null || val < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTexts.pointsPositionError(sport, positionLabel(i)),
              ),
            ),
          );
          return;
        }
        sportPoints.add(val);
      }

      roundsValues[sport] = rounds;
      durationValues[sport] = duration;
      restValues[sport] = rest;
      pointsValues[sport] = sportPoints;
    }

    try {
      for (final sport in sports) {
        await data.updateConfig(
          sport,
          rounds: roundsValues[sport]!,
          durationSeconds: durationValues[sport]!,
          restSeconds: restValues[sport]!,
          pointsByPosition: pointsValues[sport]!,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppTexts.msgSettingsSaved)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppTexts.msgSettingsSaveError}$e')),
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
      appBar: AppBar(title: const Text(AppTexts.appBarSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(AppTexts.settingsDescription),
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

                final currentPointsControllers =
                    pointsControllers[sport] ?? [];

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
                          label: AppTexts.labelRounds,
                          controller: roundsController,
                        ),
                        const SizedBox(height: 12),
                        _numberField(
                          label: AppTexts.labelCountdown,
                          controller: durationController,
                        ),
                        const SizedBox(height: 12),
                        _numberField(
                          label: AppTexts.labelRest,
                          controller: restController,
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          AppTexts.titlePointsAttribution,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppTexts.subtitlePointsAttribution,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (
                              int i = 0;
                              i < currentPointsControllers.length;
                              i++
                            )
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: currentPointsControllers[i],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: positionLabel(i),
                                    suffixText: 'pts',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _addPosition(sport),
                              icon: const Icon(Icons.add),
                              label: const Text(AppTexts.labelAdd),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: currentPointsControllers.length > 1
                                  ? () => _removePosition(sport)
                                  : null,
                              icon: const Icon(Icons.remove),
                              label: const Text(AppTexts.labelDelete),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: AppTexts.tooltipCopyPoints,
                              icon: const Icon(Icons.copy_all),
                              onPressed: () => _applyPointsToAllSports(sport),
                            ),
                          ],
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
            label: const Text(AppTexts.labelSaveSettings),
          ),
        ],
      ),
    );
  }
}
