import 'dart:async';

import 'package:flutter/material.dart';

import '../services/event_data.dart';

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
