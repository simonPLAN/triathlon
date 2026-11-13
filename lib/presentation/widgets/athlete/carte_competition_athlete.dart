import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../models/etat_inscription_utilisateur.dart';
import '../competition/badge_statut_competition.dart';
import '../competition/image_couverture_competition.dart';
import 'section_inscription_athlete.dart';

class CarteCompetitionAthlete extends StatelessWidget {
  const CarteCompetitionAthlete({
    super.key,
    required this.competition,
    required this.etatInscription,
    required this.onReessayer,
    required this.inscriptionEnCours,
    required this.desinscriptionEnCours,
    required this.onInscrire,
    required this.onDesinscrire,
    this.onVoirResultats,
    this.onVoirProgramme,
    this.onVoirDetail,
  });

  final VoidCallback? onVoirDetail;

  final Competition competition;
  final EtatInscriptionUtilisateur etatInscription;
  final VoidCallback onReessayer;
  final bool inscriptionEnCours;
  final bool desinscriptionEnCours;
  final VoidCallback? onInscrire;
  final VoidCallback? onDesinscrire;
  final VoidCallback? onVoirResultats;
  final VoidCallback? onVoirProgramme;

  @override
  Widget build(BuildContext context) {
    final possedeLieu =
        competition.lieu != null && competition.lieu!.trim().isNotEmpty;

    final possedeDescription =
        competition.description != null &&
        competition.description!.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 38,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    competition.nom,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BadgeStatutCompetition(statut: competition.statut),
            const SizedBox(height: 16),
            _InformationCompetition(
              icone: Icons.calendar_today_outlined,
              texte: _formaterDate(competition.dateCompetition),
            ),
            if (possedeLieu) ...[
              const SizedBox(height: 10),
              _InformationCompetition(
                icone: Icons.location_on_outlined,
                texte: competition.lieu!.trim(),
              ),
            ],
            if (possedeDescription) ...[
              const SizedBox(height: 12),
              Text(
                competition.description!.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onVoirDetail != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onVoirDetail,
                icon: const Icon(Icons.info_outline),
                label: const Text('Voir le détail'),
              ),
            ],
            const SizedBox(height: 16),
            SectionInscriptionAthlete(
              competition: competition,
              etat: etatInscription,
              onReessayer: onReessayer,
              inscriptionEnCours: inscriptionEnCours,
              desinscriptionEnCours: desinscriptionEnCours,
              onInscrire: onInscrire,
              onDesinscrire: onDesinscrire,
            ),
            if (onVoirProgramme != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onVoirProgramme,
                icon: const Icon(Icons.event_note),
                label: const Text('Voir le programme'),
              ),
            ],
            if (onVoirResultats != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onVoirResultats,
                icon: const Icon(Icons.leaderboard_outlined),
                label: const Text('Voir les résultats'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');

    final mois = date.month.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year}';
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
        Expanded(child: Text(texte)),
      ],
    );
  }
}
