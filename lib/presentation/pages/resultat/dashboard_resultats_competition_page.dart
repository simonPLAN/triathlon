import 'package:flutter/material.dart';

import '../../widgets/commun/carte_section.dart';
import '../../widgets/commun/message_erreur.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../controllers/dashboard_resultats_controller.dart';
import '../../controllers/epreuve_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';

class DashboardResultatsCompetitionPage extends StatefulWidget {
  const DashboardResultatsCompetitionPage({
    super.key,
    required this.competition,
    required this.epreuveController,
    required this.mancheController,
    required this.resultatController,
  });

  final Competition competition;
  final EpreuveController epreuveController;
  final MancheController mancheController;
  final ResultatController resultatController;

  @override
  State<DashboardResultatsCompetitionPage> createState() =>
      _DashboardResultatsCompetitionPageState();
}

class _DashboardResultatsCompetitionPageState
    extends State<DashboardResultatsCompetitionPage> {
  late final DashboardResultatsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardResultatsController(
      widget.epreuveController,
      widget.mancheController,
      widget.resultatController,
    )..addListener(_actualiser);
    _controller.charger(widget.competition.id);
  }

  @override
  void dispose() {
    _controller.removeListener(_actualiser);
    _controller.dispose();
    super.dispose();
  }

  void _actualiser() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard des résultats'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _controller.chargement
                ? null
                : () => _controller.charger(widget.competition.id),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _controller.chargement
          ? const Center(child: CircularProgressIndicator())
          : _controller.erreur != null
          ? _ErreurDashboard(
              message: _controller.erreur!,
              onReessayer: () => _controller.charger(widget.competition.id),
            )
          : RefreshIndicator(
              onRefresh: () => _controller.charger(widget.competition.id),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  CarteSection(
                    titre: widget.competition.nom,
                    sousTitre: 'Vue d’ensemble des résultats de la compétition',
                    icone: Icons.leaderboard_outlined,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            '${_controller.classement.length} athlète(s) classé(s)',
                          ),
                        ),
                        Chip(
                          label: Text(
                            '${_controller.lignes.length} résultat(s)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FiltreEpreuve(
                    epreuves: _controller.epreuves,
                    valeur: _controller.filtreEpreuveId,
                    onChanged: _controller.filtrerParEpreuve,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Classement cumulé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_controller.classement.isEmpty)
                    const Text('Aucun résultat enregistré.')
                  else
                    ..._controller.classement.asMap().entries.map(
                      (entry) => _CarteClassement(
                        rang: entry.key + 1,
                        classement: entry.value,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Détail par manche',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_controller.lignes.isEmpty)
                    const Text('Aucun détail disponible.')
                  else
                    ..._controller.lignes.map(
                      (ligne) => _CarteDetail(ligne: ligne),
                    ),
                ],
              ),
            ),
    );
  }
}

class _FiltreEpreuve extends StatelessWidget {
  const _FiltreEpreuve({
    required this.epreuves,
    required this.valeur,
    required this.onChanged,
  });

  final List<Epreuve> epreuves;
  final String? valeur;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: valeur,
      decoration: const InputDecoration(
        labelText: 'Filtrer par épreuve',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Toutes les épreuves'),
        ),
        ...epreuves.map(
          (epreuve) => DropdownMenuItem<String?>(
            value: epreuve.id,
            child: Text(epreuve.nom),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CarteClassement extends StatelessWidget {
  const _CarteClassement({required this.rang, required this.classement});

  final int rang;
  final DashboardAthleteStanding classement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('$rang')),
        title: Text(classement.nom),
        subtitle: Text('${classement.manches} manche(s) comptabilisée(s)'),
        trailing: Text(
          '${classement.points} pt',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _CarteDetail extends StatelessWidget {
  const _CarteDetail({required this.ligne});

  final DashboardResultatLine ligne;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(ligne.resultat.athlete.nomComplet),
        subtitle: Text(
          '${ligne.epreuve.nom} • Manche ${ligne.manche.numero} • '
          '${ligne.resultat.statut.name}',
        ),
        trailing: Text('${ligne.resultat.points} pt'),
      ),
    );
  }
}

class _ErreurDashboard extends StatelessWidget {
  const _ErreurDashboard({required this.message, required this.onReessayer});
  final String message;
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) => MessageErreur(
    titre: 'Impossible de charger le classement',
    message: message,
    onReessayer: onReessayer,
  );
}
