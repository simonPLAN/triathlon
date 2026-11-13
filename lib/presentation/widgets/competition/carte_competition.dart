import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import 'badge_statut_competition.dart';
import 'image_couverture_competition.dart';

class CarteCompetition extends StatelessWidget {
  const CarteCompetition({
    super.key,
    required this.competition,
    required this.onTap,
  });

  final Competition competition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (competition.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ImageCouvertureCompetition(
                    url: competition.imageUrl!,
                    nomCompetition: competition.nom,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _EnteteCompetition(competition: competition),
              const SizedBox(height: 14),
              _InformationCompetition(
                icone: Icons.calendar_today_outlined,
                texte: _formaterDate(competition.dateCompetition),
              ),
              if (_possedeLieu) ...[
                const SizedBox(height: 10),
                _InformationCompetition(
                  icone: Icons.location_on_outlined,
                  texte: competition.lieu!.trim(),
                ),
              ],
              if (_possedeDescription) ...[
                const SizedBox(height: 14),
                Text(
                  competition.description!.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Voir le détail'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _possedeLieu {
    return competition.lieu != null && competition.lieu!.trim().isNotEmpty;
  }

  bool get _possedeDescription {
    return competition.description != null &&
        competition.description!.trim().isNotEmpty;
  }

  String _formaterDate(DateTime date) {
    const nomsMois = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${date.day} '
        '${nomsMois[date.month - 1]} '
        '${date.year}';
  }
}

class _EnteteCompetition extends StatelessWidget {
  const _EnteteCompetition({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                competition.nom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              BadgeStatutCompetition(statut: competition.statut),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationCompetition extends StatelessWidget {
  const _InformationCompetition({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texte, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
