import 'dart:async';

import 'package:flutter/material.dart';

class ChronometreManche extends StatefulWidget {
  const ChronometreManche({super.key, required this.heureFinDelai});

  final DateTime heureFinDelai;

  @override
  State<ChronometreManche> createState() {
    return _ChronometreMancheState();
  }
}

class _ChronometreMancheState extends State<ChronometreManche> {
  Timer? _timer;
  Duration _tempsRestant = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculerTempsRestant();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculerTempsRestant();
    });
  }

  @override
  void didUpdateWidget(covariant ChronometreManche oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.heureFinDelai != widget.heureFinDelai) {
      _calculerTempsRestant();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculerTempsRestant() {
    final difference = widget.heureFinDelai.difference(DateTime.now());

    final nouvelleValeur = difference.isNegative ? Duration.zero : difference;

    if (!mounted) {
      return;
    }

    setState(() {
      _tempsRestant = nouvelleValeur;
    });

    if (_tempsRestant == Duration.zero) {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _tempsRestant.inMinutes;
    final secondes = _tempsRestant.inSeconds.remainder(60);

    final texteMinutes = minutes.toString().padLeft(2, '0');
    final texteSecondes = secondes.toString().padLeft(2, '0');

    final delaiEcoule = _tempsRestant == Duration.zero;

    return Card(
      color: delaiEcoule
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              delaiEcoule ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              delaiEcoule ? 'Délai écoulé' : '$texteMinutes:$texteSecondes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              delaiEcoule
                  ? 'Les athlètes restants sont hors délai.'
                  : 'Temps restant après le premier arrivé',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
