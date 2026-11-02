import 'dart:async';

import 'package:flutter/material.dart';

class CompteAReboursResultat extends StatefulWidget {
  const CompteAReboursResultat({
    super.key,
    required this.heureFinDelai,
    required this.onDelaiEcoule,
  });

  final DateTime heureFinDelai;
  final VoidCallback onDelaiEcoule;

  @override
  State<CompteAReboursResultat> createState() {
    return _CompteAReboursResultatState();
  }
}

class _CompteAReboursResultatState extends State<CompteAReboursResultat> {
  Timer? _timer;
  Duration _tempsRestant = Duration.zero;
  bool _notificationEnvoyee = false;

  @override
  void initState() {
    super.initState();

    _mettreAJourTemps();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _mettreAJourTemps();
    });
  }

  @override
  void didUpdateWidget(covariant CompteAReboursResultat oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.heureFinDelai != widget.heureFinDelai) {
      _notificationEnvoyee = false;
      _mettreAJourTemps();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _mettreAJourTemps() {
    final difference = widget.heureFinDelai.difference(DateTime.now());

    final tempsRestant = difference.isNegative ? Duration.zero : difference;

    if (mounted) {
      setState(() {
        _tempsRestant = tempsRestant;
      });
    }

    if (tempsRestant == Duration.zero) {
      _timer?.cancel();
      _notifierDelaiEcoule();
    }
  }

  void _notifierDelaiEcoule() {
    if (_notificationEnvoyee) {
      return;
    }

    _notificationEnvoyee = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDelaiEcoule();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final delaiEcoule = _tempsRestant == Duration.zero;

    final minutes = _tempsRestant.inMinutes;

    final secondes = _tempsRestant.inSeconds.remainder(60);

    final texteMinutes = minutes.toString().padLeft(2, '0');

    final texteSecondes = secondes.toString().padLeft(2, '0');

    final couleurs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: delaiEcoule
          ? couleurs.errorContainer
          : couleurs.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            delaiEcoule ? Icons.timer_off_outlined : Icons.timer_outlined,
            color: delaiEcoule
                ? couleurs.onErrorContainer
                : couleurs.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delaiEcoule ? 'Délai écoulé' : 'Temps restant',
                  style: TextStyle(
                    color: delaiEcoule
                        ? couleurs.onErrorContainer
                        : couleurs.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  delaiEcoule
                      ? 'Les athlètes restants '
                            'peuvent être marqués '
                            'hors délai.'
                      : '$texteMinutes:$texteSecondes',
                  style: TextStyle(
                    color: delaiEcoule
                        ? couleurs.onErrorContainer
                        : couleurs.onSecondaryContainer,
                    fontSize: delaiEcoule ? null : 22,
                    fontWeight: delaiEcoule
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
