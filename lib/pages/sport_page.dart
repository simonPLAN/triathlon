import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/sports.dart';
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
    return duration > 0 ? duration : defaultDurationSeconds;
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

  Future<void> addParticipantArrival(String name) async {
    if (roundFinished || isFinishing || isFinished || isResting) {
      return;
    }

    await data.addArrival(widget.sport, currentRound, name);

    if (!mounted) return;

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
            tooltip: AppTexts.tooltipResetSport,
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

          String status;

          if (isFinished) {
            status = AppTexts.statusFinished;
          } else if (isResting) {
            status = AppTexts.statusResting;
          } else if (isRunning) {
            status = AppTexts.statusRunning;
          } else {
            status = AppTexts.statusWaiting;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isFinished
                      ? AppTexts.statusFinished
                      : AppTexts.roundLabel(currentRound + 1, roundCount),
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
                            AppTexts.countdownInfo,
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
                  const Text(
                    AppTexts.instructionTapParticipant,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 132,
                    child: GridView.builder(
                      itemCount: availableParticipants.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 3.2,
                          ),
                      itemBuilder: (context, index) {
                        final participant = availableParticipants[index];

                        return FilledButton(
                          onPressed: roundFinished || isFinishing
                              ? null
                              : () => addParticipantArrival(participant),
                          child: Text(
                            participant,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),

                  if (arrivals.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: roundFinished || isFinishing
                          ? null
                          : () async {
                              await data.undoLastArrival(
                                widget.sport,
                                currentRound,
                              );
                            },
                      icon: const Icon(Icons.undo),
                      label: const Text(AppTexts.labelUndoLastArrival),
                    ),
                  ],

                  if (isRunning) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: isFinishing ? null : finishCurrentRound,
                      child: const Text(AppTexts.labelFinishRoundNow),
                    ),
                  ],
                ],

                const SizedBox(height: 16),
                Text(
                  AppTexts.arrivalOrderWithCount(arrivals.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: arrivals.isEmpty
                      ? const Center(child: Text(AppTexts.msgNoArrivals))
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
                                subtitle: Text(
                                  AppTexts.arrivalPositionLabel(index + 1),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (isFinished)
                  FilledButton.icon(
                    onPressed: resetSport,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text(AppTexts.labelRestartSport),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
