import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../controllers/competitions_ouvertes_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../widgets/athlete/section_inscription_athlete.dart';
import '../../widgets/commun/carte_section.dart';
import '../../widgets/competition/badge_statut_competition.dart';

/// Présentation en lecture seule ; les seules écritures sont celles de son inscription.
class DetailCompetitionAthletePage extends StatefulWidget {
  const DetailCompetitionAthletePage({
    super.key,
    required this.competition,
    required this.competitions,
    required this.inscriptions,
    required this.onInscrire,
    required this.onDesinscrire,
    required this.onProgramme,
    required this.onResultats,
  });
  final Competition competition;
  final CompetitionsOuvertesController competitions;
  final InscriptionController inscriptions;
  final Future<void> Function(Competition) onInscrire;
  final Future<void> Function(Competition) onDesinscrire;
  final void Function(Competition) onProgramme;
  final void Function(Competition) onResultats;

  @override
  State<DetailCompetitionAthletePage> createState() =>
      _DetailCompetitionAthletePageState();
}

class _DetailCompetitionAthletePageState
    extends State<DetailCompetitionAthletePage>
    with WidgetsBindingObserver {
  bool _actualisation = false;

  Competition get _competition {
    for (final c in [
      ...widget.competitions.inscrites,
      ...widget.competitions.competitions,
    ]) {
      if (c.id == widget.competition.id) return c;
    }
    return widget.competition;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.competitions.addListener(_actualiser);
    widget.inscriptions.addListener(_actualiser);
    widget.inscriptions.verifierInscriptionUtilisateur(
      competition: _competition,
    );
  }

  void _actualiser() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recharger();
  }

  Future<void> _recharger() async {
    if (_actualisation) return;
    setState(() => _actualisation = true);
    try {
      await widget.competitions.recharger();
      if (!mounted) return;
      await widget.inscriptions.verifierInscriptionUtilisateur(
        competition: _competition,
      );
    } finally {
      if (mounted) setState(() => _actualisation = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.competitions.removeListener(_actualiser);
    widget.inscriptions.removeListener(_actualiser);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _competition;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la compétition'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _actualisation ? null : _recharger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _recharger,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_actualisation) const LinearProgressIndicator(),
                  if (widget.competitions.erreur != null ||
                      widget.competitions.erreurInscriptions != null)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Actualisation incomplète. Les dernières informations connues restent affichées. Réessaie avec Actualiser.',
                      ),
                    ),
                  CarteSection(
                    titre: c.nom,
                    icone: Icons.emoji_events_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BadgeStatutCompetition(statut: c.statut),
                        const SizedBox(height: 16),
                        Text(
                          'Date : ${c.dateCompetition.day.toString().padLeft(2, '0')}/${c.dateCompetition.month.toString().padLeft(2, '0')}/${c.dateCompetition.year}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.lieu?.trim().isNotEmpty == true
                              ? 'Lieu : ${c.lieu}'
                              : 'Lieu non précisé',
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          c.description?.trim().isNotEmpty == true
                              ? c.description!
                              : 'Aucune description fournie.',
                        ),
                      ],
                    ),
                  ),
                  CarteSection(
                    titre: 'Mon inscription',
                    icone: Icons.how_to_reg_outlined,
                    child: SectionInscriptionAthlete(
                      competition: c,
                      etat: widget.inscriptions.suiviUtilisateur.pour(c.id),
                      inscriptionEnCours:
                          widget.inscriptions.inscriptionEnCours,
                      desinscriptionEnCours:
                          widget.inscriptions.desinscriptionEnCours,
                      onReessayer: () => widget.inscriptions
                          .verifierInscriptionUtilisateur(competition: c),
                      onInscrire: _actualisation
                          ? null
                          : () => widget.onInscrire(c),
                      onDesinscrire: _actualisation
                          ? null
                          : () => widget.onDesinscrire(c),
                    ),
                  ),
                  CarteSection(
                    titre: 'Programme et classements',
                    icone: Icons.insights_outlined,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => widget.onProgramme(c),
                          icon: const Icon(Icons.event_note_outlined),
                          label: const Text('Voir le programme'),
                        ),
                        FilledButton.icon(
                          onPressed: () => widget.onResultats(c),
                          icon: const Icon(Icons.leaderboard_outlined),
                          label: const Text('Résultats publiés'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
