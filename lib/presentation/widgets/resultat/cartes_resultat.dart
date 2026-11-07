import 'package:flutter/material.dart';

import '../../formatters/temps_resultat.dart';

import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';

class CarteParticipantArrivee extends StatelessWidget {
  const CarteParticipantArrivee({
    super.key,
    required this.inscription,
    required this.active,
    required this.onTap,
  });

  final Inscription inscription;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: active ? couleurs.primaryContainer : couleurs.surfaceContainer,
      child: InkWell(
        onTap: active ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  inscription.numeroDossard == null
                      ? '—'
                      : '${inscription.numeroDossard}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: active ? couleurs.onPrimaryContainer : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inscription.athlete.nomComplet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: active ? couleurs.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EnteteResultats extends StatelessWidget {
  const EnteteResultats({
    super.key,
    required this.manche,
    required this.nombreInscrits,
    required this.nombreResultats,
  });

  final Manche manche;
  final int nombreInscrits;
  final int nombreResultats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 38,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manche ${manche.numero}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$nombreResultats résultat(s) '
                  'sur $nombreInscrits athlète(s)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CarteResultat extends StatelessWidget {
  const CarteResultat({
    super.key,
    required this.resultat,
    required this.onCorriger,
  });

  final Resultat resultat;
  final VoidCallback? onCorriger;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            PositionResultat(resultat: resultat),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultat.athlete.nomComplet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _libelleStatut(resultat),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (resultat.heureArrivee != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Arrivée à '
                      '${_formaterHeure(resultat.heureArrivee!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (resultat.ecartPremierMillisecondes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Écart au premier classé : ${TempsResultat.formater(resultat.ecartPremierMillisecondes!)}',
                    ),
                  ],
                  if (resultat.estArrive &&
                      resultat.tempsTotalMillisecondes == null)
                    const Text('Temps à compléter avant publication.'),
                  if (resultat.tempsTotalMillisecondes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Temps : '
                      '${_formaterDuree(resultat.tempsTotalMillisecondes!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Corriger le résultat',
              onPressed: onCorriger,
              icon: const Icon(Icons.edit_outlined),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${resultat.points} pt'
                '${resultat.points > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _libelleStatut(Resultat resultat) {
    switch (resultat.statut) {
      case StatutResultat.arrive:
        return 'Arrivé';

      case StatutResultat.horsDelai:
        return 'Hors délai';

      case StatutResultat.abandon:
        return 'Abandon';

      case StatutResultat.disqualifie:
        return 'Disqualifié';
    }
  }

  String _formaterHeure(DateTime date) {
    final heure = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    final seconde = date.second.toString().padLeft(2, '0');

    return '$heure:$minute:$seconde';
  }

  String _formaterDuree(int millisecondes) {
    final duree = Duration(milliseconds: millisecondes);

    final minutes = duree.inMinutes.toString().padLeft(2, '0');

    final secondes = duree.inSeconds.remainder(60).toString().padLeft(2, '0');

    final milliemes = duree.inMilliseconds
        .remainder(1000)
        .toString()
        .padLeft(3, '0');

    return '$minutes:$secondes.$milliemes';
  }
}

class PositionResultat extends StatelessWidget {
  const PositionResultat({super.key, required this.resultat});

  final Resultat resultat;

  @override
  Widget build(BuildContext context) {
    final position = resultat.position;

    return CircleAvatar(
      radius: 25,
      backgroundColor: position == 1
          ? Colors.amber.shade200
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: position == null
          ? const Icon(Icons.remove)
          : Text(
              '$position',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
    );
  }
}
