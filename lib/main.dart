import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> sports = ['Natation', 'Vélo', 'Course à pied'];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EventData.instance.load();
  runApp(const TriathlonApp());
}

// ============================================================
// CONFIGURATION D'UN SPORT
// ============================================================

class SportConfig {
  int rounds;
  int durationSeconds;
  int restSeconds;

  SportConfig({
    required this.rounds,
    required this.durationSeconds,
    required this.restSeconds,
  });

  Map<String, dynamic> toJson() => {
    'rounds': rounds,
    'durationSeconds': durationSeconds,
    'restSeconds': restSeconds,
  };

  factory SportConfig.fromJson(Map<String, dynamic> json) {
    return SportConfig(
      rounds: ((json['rounds'] as num?)?.toInt() ?? 1).clamp(1, 100),
      durationSeconds: ((json['durationSeconds'] as num?)?.toInt() ?? 180)
          .clamp(1, 86400),
      restSeconds: ((json['restSeconds'] as num?)?.toInt() ?? 90).clamp(
        0,
        86400,
      ),
    );
  }
}

// ============================================================
// DONNÉES ET SAUVEGARDE
// ============================================================

class EventData extends ChangeNotifier {
  EventData._();

  static final EventData instance = EventData._();

  static const String _storageKey = 'triathlon_data_v1';

  final List<String> participants = [];

  final Map<String, SportConfig> _configs = {
    'Natation': SportConfig(rounds: 9, durationSeconds: 180, restSeconds: 90),
    'Vélo': SportConfig(rounds: 3, durationSeconds: 180, restSeconds: 90),
    'Course à pied': SportConfig(
      rounds: 2,
      durationSeconds: 180,
      restSeconds: 90,
    ),
  };

  final Map<String, Map<int, List<String>>> _arrivals = {
    for (final sport in sports) sport: <int, List<String>>{},
  };

  final Map<String, Set<int>> _completedRounds = {
    for (final sport in sports) sport: <int>{},
  };

  SportConfig config(String sport) {
    final result = _configs[sport];

    if (result == null) {
      throw StateError(
        'Configuration introuvable pour "$sport". '
        'Sports disponibles : ${_configs.keys.join(", ")}',
      );
    }

    return result;
  }

  Map<int, List<String>> _sportArrivals(String sport) {
    return _arrivals.putIfAbsent(sport, () => <int, List<String>>{});
  }

  Set<int> _sportCompletedRounds(String sport) {
    return _completedRounds.putIfAbsent(sport, () => <int>{});
  }

  List<String> arrivals(String sport, int round) {
    return List<String>.unmodifiable(
      _sportArrivals(sport)[round] ?? <String>[],
    );
  }

  bool isRoundCompleted(String sport, int round) {
    return _sportCompletedRounds(sport).contains(round);
  }

  int firstUncompletedRound(String sport) {
    for (int i = 0; i < config(sport).rounds; i++) {
      if (!isRoundCompleted(sport, i)) {
        return i;
      }
    }

    return config(sport).rounds;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);

      if (decoded is! Map) return;

      final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);

      participants
        ..clear()
        ..addAll(
          (json['participants'] as List<dynamic>? ?? []).map(
            (e) => e.toString(),
          ),
        );

      final savedConfigs = json['configs'];

      if (savedConfigs is Map) {
        for (final sport in sports) {
          final saved = savedConfigs[sport];

          if (saved is Map) {
            _configs[sport] = SportConfig.fromJson(
              Map<String, dynamic>.from(saved),
            );
          }
        }
      }

      final savedArrivals = json['arrivals'];

      if (savedArrivals is Map) {
        for (final sport in sports) {
          final destination = _sportArrivals(sport);
          destination.clear();

          final sportData = savedArrivals[sport];

          if (sportData is Map) {
            sportData.forEach((key, value) {
              final round = int.tryParse(key.toString());

              if (round != null && value is List) {
                destination[round] = value.map((e) => e.toString()).toList();
              }
            });
          }
        }
      }

      final savedCompleted = json['completedRounds'];

      if (savedCompleted is Map) {
        for (final sport in sports) {
          final destination = _sportCompletedRounds(sport);
          destination.clear();

          final rounds = savedCompleted[sport];

          if (rounds is List) {
            for (final round in rounds) {
              final value = int.tryParse(round.toString());

              if (value != null) {
                destination.add(value);
              }
            }
          }
        }
      }

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Erreur de chargement des données : $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> savedArrivals = {};
    final Map<String, dynamic> savedCompleted = {};

    for (final sport in sports) {
      final sportArrivals = _sportArrivals(sport);

      savedArrivals[sport] = {
        for (final entry in sportArrivals.entries)
          entry.key.toString(): entry.value,
      };

      savedCompleted[sport] = _sportCompletedRounds(sport).toList();
    }

    final json = {
      'participants': participants,
      'configs': {
        for (final entry in _configs.entries) entry.key: entry.value.toJson(),
      },
      'arrivals': savedArrivals,
      'completedRounds': savedCompleted,
    };

    await prefs.setString(_storageKey, jsonEncode(json));
  }

  Future<bool> addParticipant(String name) async {
    final cleaned = name.trim();

    if (cleaned.isEmpty ||
        participants.any((p) => p.toLowerCase() == cleaned.toLowerCase())) {
      return false;
    }

    participants.add(cleaned);
    await _save();
    notifyListeners();

    return true;
  }

  Future<void> removeParticipant(String name) async {
    participants.remove(name);

    for (final sport in sports) {
      for (final list in _sportArrivals(sport).values) {
        list.remove(name);
      }
    }

    await _save();
    notifyListeners();
  }

  Future<void> updateConfig(
    String sport, {
    required int rounds,
    required int durationSeconds,
    required int restSeconds,
  }) async {
    if (!sports.contains(sport)) {
      throw ArgumentError('Sport inconnu : $sport');
    }

    _configs[sport] = SportConfig(
      rounds: rounds.clamp(1, 100),
      durationSeconds: durationSeconds.clamp(1, 86400),
      restSeconds: restSeconds.clamp(0, 86400),
    );

    await _save();
    notifyListeners();
  }

  Future<void> addArrival(String sport, int round, String participant) async {
    if (round < 0 || round >= config(sport).rounds) return;
    if (!participants.contains(participant)) return;
    if (isRoundCompleted(sport, round)) return;

    final list = _sportArrivals(sport).putIfAbsent(round, () => <String>[]);

    if (list.contains(participant)) return;

    list.add(participant);

    await _save();
    notifyListeners();
  }

  Future<void> finishRound(String sport, int round) async {
    if (round < 0 || round >= config(sport).rounds) return;

    _sportCompletedRounds(sport).add(round);

    await _save();
    notifyListeners();
  }

  Future<void> resetSport(String sport) async {
    _sportArrivals(sport).clear();
    _sportCompletedRounds(sport).clear();

    await _save();
    notifyListeners();
  }

  Future<void> resetAll() async {
    participants.clear();

    for (final sport in sports) {
      _sportArrivals(sport).clear();
      _sportCompletedRounds(sport).clear();
    }

    await _save();
    notifyListeners();
  }

  Map<String, int> pointsForSport(String sport) {
    final scores = <String, int>{
      for (final participant in participants) participant: 0,
    };

    for (final entry in _sportArrivals(sport).entries) {
      final arrivalList = entry.value;

      for (int i = 0; i < arrivalList.length; i++) {
        final participant = arrivalList[i];

        final points = (participants.length - i)
            .clamp(0, participants.length)
            .toInt();

        scores[participant] = (scores[participant] ?? 0) + points;
      }
    }

    return scores;
  }

  Map<String, int> generalPoints() {
    final scores = <String, int>{
      for (final participant in participants) participant: 0,
    };

    for (final sport in sports) {
      final sportScores = pointsForSport(sport);

      for (final entry in sportScores.entries) {
        scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
      }
    }

    return scores;
  }
}

// ============================================================
// APPLICATION
// ============================================================

class TriathlonApp extends StatelessWidget {
  const TriathlonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triathlon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// ACCUEIL
// ============================================================

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

// ============================================================
// PARTICIPANTS
// ============================================================

class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  final EventData data = EventData.instance;
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> addParticipant() async {
    final name = controller.text.trim();

    if (name.isEmpty) return;

    final added = await data.addParticipant(name);

    if (!mounted) return;

    if (added) {
      controller.clear();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Participant ajouté')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom vide ou participant déjà présent')),
      );
    }
  }

  Future<void> confirmRemove(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le participant ?'),
          content: Text('Supprimer $name et ses arrivées enregistrées ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await data.removeParticipant(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Nom du participant',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: addParticipant,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: data,
                builder: (context, _) {
                  if (data.participants.isEmpty) {
                    return const Center(
                      child: Text('Aucun participant enregistré'),
                    );
                  }

                  return ListView.builder(
                    itemCount: data.participants.length,
                    itemBuilder: (context, index) {
                      final name = data.participants[index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(name),
                          trailing: IconButton(
                            tooltip: 'Supprimer',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => confirmRemove(name),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RÉGLAGES DES ÉPREUVES
// ============================================================

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

// ============================================================
// ÉPREUVES : NATATION, VÉLO ET COURSE À PIED
// ============================================================

class SportPage extends StatefulWidget {
  final String sport;

  const SportPage({super.key, required this.sport});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  final EventData data = EventData.instance;

  int currentRound = 0;
  int secondsLeft = 0;

  bool isResting = false;
  bool isRunning = false;
  bool isFinished = false;
  bool roundFinished = false;
  bool isFinishing = false;

  Timer? ticker;
  DateTime? deadline;

  String? selectedParticipant;

  int get roundCount => data.config(widget.sport).rounds;

  int get arrivalDuration {
    final duration = data.config(widget.sport).durationSeconds;
    return duration > 0 ? duration : 180;
  }

  @override
  void initState() {
    super.initState();

    currentRound = data.firstUncompletedRound(widget.sport);
    isFinished = currentRound >= roundCount;
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  Future<void> addSelectedParticipant() async {
    if (selectedParticipant == null || roundFinished || isFinishing) {
      return;
    }

    final name = selectedParticipant!;

    await data.addArrival(widget.sport, currentRound, name);

    if (!mounted) return;

    setState(() {
      selectedParticipant = null;
    });

    if (!isRunning && data.arrivals(widget.sport, currentRound).isNotEmpty) {
      startArrivalTimer();
    }
  }

  void startArrivalTimer() {
    if (isRunning || isResting || isFinished || roundFinished || isFinishing) {
      return;
    }

    if (data.arrivals(widget.sport, currentRound).isEmpty) {
      return;
    }

    ticker?.cancel();

    setState(() {
      isRunning = true;
      secondsLeft = arrivalDuration;
      deadline = DateTime.now().add(Duration(seconds: arrivalDuration));
    });

    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final end = deadline;

      if (end == null || !mounted) return;

      final remaining = end.difference(DateTime.now()).inSeconds;

      if (remaining <= 0) {
        ticker?.cancel();
        finishCurrentRound();
      } else {
        setState(() {
          secondsLeft = remaining;
        });
      }
    });
  }

  Future<void> finishCurrentRound() async {
    if (isFinished || roundFinished || isFinishing) return;

    isFinishing = true;
    ticker?.cancel();
    deadline = null;

    await data.finishRound(widget.sport, currentRound);

    if (!mounted) return;

    setState(() {
      isRunning = false;
      roundFinished = true;
      isFinishing = false;
    });

    if (currentRound >= roundCount - 1) {
      setState(() {
        isFinished = true;
        isResting = false;
        secondsLeft = 0;
      });

      return;
    }

    startRestCountdown();
  }

  void startRestCountdown() {
    final rest = data.config(widget.sport).restSeconds;

    if (rest <= 0) {
      moveToNextRound();
      return;
    }

    ticker?.cancel();

    setState(() {
      isResting = true;
      isRunning = false;
      secondsLeft = rest;
      deadline = DateTime.now().add(Duration(seconds: rest));
    });

    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final end = deadline;

      if (end == null || !mounted) return;

      final remaining = end.difference(DateTime.now()).inSeconds;

      if (remaining <= 0) {
        ticker?.cancel();
        moveToNextRound();
      } else {
        setState(() {
          secondsLeft = remaining;
        });
      }
    });
  }

  void moveToNextRound() {
    ticker?.cancel();
    deadline = null;

    if (!mounted) return;

    setState(() {
      currentRound++;
      secondsLeft = 0;
      isResting = false;
      isRunning = false;
      roundFinished = false;
      isFinishing = false;
      isFinished = currentRound >= roundCount;
      selectedParticipant = null;
    });

    if (!isFinished && data.isRoundCompleted(widget.sport, currentRound)) {
      setState(() {
        currentRound = data.firstUncompletedRound(widget.sport);
        isFinished = currentRound >= roundCount;
      });
    }
  }

  Future<void> resetSport() async {
    ticker?.cancel();
    deadline = null;

    await data.resetSport(widget.sport);

    if (!mounted) return;

    setState(() {
      currentRound = 0;
      secondsLeft = 0;
      isResting = false;
      isRunning = false;
      isFinished = false;
      roundFinished = false;
      isFinishing = false;
      selectedParticipant = null;
    });
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sport),
        actions: [
          IconButton(
            tooltip: 'Réinitialiser cette épreuve',
            icon: const Icon(Icons.restart_alt),
            onPressed: resetSport,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: data,
        builder: (context, _) {
          final participants = data.participants;

          final arrivals = isFinished
              ? <String>[]
              : data.arrivals(widget.sport, currentRound);

          final availableParticipants = participants
              .where((p) => !arrivals.contains(p))
              .toList();

          final dropdownValue =
              availableParticipants.contains(selectedParticipant)
              ? selectedParticipant
              : null;

          String status;

          if (isFinished) {
            status = 'Épreuve terminée';
          } else if (isResting) {
            status = 'Repos avant la prochaine manche';
          } else if (isRunning) {
            status = 'Temps restant pour les arrivées';
          } else {
            status = 'En attente de la première arrivée';
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isFinished
                      ? 'Épreuve terminée'
                      : 'Manche ${currentRound + 1} / $roundCount',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(status, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        if (!isFinished)
                          Text(
                            formatTime(
                              isRunning || isResting
                                  ? secondsLeft
                                  : arrivalDuration,
                            ),
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        if (!isRunning && !isResting && !isFinished)
                          const Text(
                            'Le compte à rebours démarre '
                            'à la première arrivée.',
                            textAlign: TextAlign.center,
                          ),
                        if (isFinished)
                          const Icon(Icons.emoji_events, size: 48),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!isFinished && !isResting) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('participant_${widget.sport}_$currentRound'),
                    initialValue: dropdownValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Participant arrivé',
                      border: OutlineInputBorder(),
                    ),
                    items: availableParticipants
                        .map(
                          (participant) => DropdownMenuItem<String>(
                            value: participant,
                            child: Text(participant),
                          ),
                        )
                        .toList(),
                    onChanged: roundFinished || isFinishing
                        ? null
                        : (value) {
                            setState(() {
                              selectedParticipant = value;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        selectedParticipant == null ||
                            roundFinished ||
                            isFinishing
                        ? null
                        : addSelectedParticipant,
                    icon: const Icon(Icons.add),
                    label: const Text('Enregistrer l’arrivée'),
                  ),
                  if (isRunning) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: isFinishing ? null : finishCurrentRound,
                      child: const Text('Terminer la manche maintenant'),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Text(
                  'Ordre des arrivées (${arrivals.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: arrivals.isEmpty
                      ? const Center(child: Text('Aucune arrivée enregistrée.'))
                      : ListView.builder(
                          itemCount: arrivals.length,
                          itemBuilder: (context, index) {
                            final participant = arrivals[index];

                            return Card(
                              key: ValueKey(
                                '${widget.sport}_$currentRound'
                                '_$participant',
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(participant),
                                subtitle: Text('Position ${index + 1}'),
                              ),
                            );
                          },
                        ),
                ),
                if (isFinished)
                  FilledButton.icon(
                    onPressed: resetSport,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Recommencer cette épreuve'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// RÉSULTATS ET CLASSEMENTS
// ============================================================

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
                    subtitle: Text('${data.config(sport).rounds} manches'),
                    children: [scoreList(context, data.pointsForSport(sport))],
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Les points dépendent de l’ordre des arrivées '
                'dans chaque manche. Le classement général '
                'additionne les points des trois sports.',
              ),
            ],
          );
        },
      ),
    );
  }
}
