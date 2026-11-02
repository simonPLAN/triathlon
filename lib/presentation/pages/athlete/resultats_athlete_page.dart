import 'package:flutter/material.dart';

import '../../widgets/resultat/classement_general_athlete.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/resultat_publie.dart';
import '../../controllers/competitions_ouvertes_controller.dart';

class ResultatsAthletePage extends StatefulWidget {
  const ResultatsAthletePage({
    super.key,
    required this.competition,
    required this.controller,
    required this.athleteId,
  });
  final Competition competition;
  final CompetitionsOuvertesController controller;
  final String athleteId;

  @override
  State<ResultatsAthletePage> createState() => _ResultatsAthletePageState();
}

class _ResultatsAthletePageState extends State<ResultatsAthletePage> {
  late Future<List<ResultatPublie>> _future;
  bool _mesResultats = false;
  bool _vueGlobale = true;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.resultatsPublies(widget.competition.id);
  }

  Future<void> _recharger() async {
    final future = widget.controller.resultatsPublies(widget.competition.id);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      /* Affiché par FutureBuilder. */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.competition.nom),
        actions: [
          IconButton(
            onPressed: _recharger,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<ResultatPublie>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.error.toString().replaceFirst(
                          'Bad state: ',
                          '',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _recharger,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final toutes = snapshot.data ?? const [];
            final lignes = toutes
                .where((r) => !_mesResultats || r.athleteId == widget.athleteId)
                .toList();
            final groupes = <String, List<ResultatPublie>>{};
            for (final ligne in lignes) {
              groupes.putIfAbsent(ligne.mancheId, () => []).add(ligne);
            }
            final points = toutes
                .where((r) => r.athleteId == widget.athleteId)
                .fold<int>(0, (total, r) => total + r.points);
            return RefreshIndicator(
              onRefresh: _recharger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Résultats publiés',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Ton total : $points point(s) sur les manches publiées'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Général'),
                        selected: _vueGlobale,
                        onSelected: (_) => setState(() => _vueGlobale = true),
                      ),
                      ChoiceChip(
                        label: const Text('Par manche'),
                        selected: !_vueGlobale,
                        onSelected: (_) => setState(() => _vueGlobale = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mes résultats uniquement'),
                    value: _mesResultats,
                    onChanged: (value) => setState(() => _mesResultats = value),
                  ),
                  if (toutes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Le coach n’a pas encore publié de résultats.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (lignes.isEmpty)
                    const Text(
                      'Tu n’as pas encore de résultat dans les manches publiées.',
                    ),
                  if (_vueGlobale && lignes.isNotEmpty)
                    ClassementGeneralAthlete(
                      resultats: toutes,
                      athleteId: widget.athleteId,
                      uniquementMoi: _mesResultats,
                    ),
                  if (!_vueGlobale)
                    for (final groupe in groupes.values) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${groupe.first.nomEpreuve} • Manche ${groupe.first.numeroManche}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final r in groupe)
                        Card(
                          color: r.athleteId == widget.athleteId
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(r.position?.toString() ?? '—'),
                            ),
                            title: Text(r.nomAthlete),
                            subtitle: Text(_description(r)),
                            trailing: Text('${r.points} pt'),
                          ),
                        ),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _description(ResultatPublie r) {
    final statut = switch (r.statut) {
      'arrive' => 'Arrivé',
      'hors_delai' => 'Hors délai',
      'abandon' => 'Abandon',
      'disqualifie' => 'Disqualifié',
      _ => r.statut,
    };
    final ms = r.tempsMillisecondes;
    if (ms == null) return statut;
    final duree = Duration(milliseconds: ms);
    final secondes = duree.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$statut • ${duree.inMinutes}:$secondes';
  }
}
