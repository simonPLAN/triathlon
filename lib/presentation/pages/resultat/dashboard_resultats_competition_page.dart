import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../controllers/epreuve_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';

class DashboardResultatsCompetitionPage extends StatefulWidget {
  const DashboardResultatsCompetitionPage({
    super.key,
    required this.competition,
    required this.epreuveController,
    required this.mancheController,
    required this.resultatController,
    required this.inscriptionController,
  });

  final Competition competition;
  final EpreuveController epreuveController;
  final MancheController mancheController;
  final ResultatController resultatController;
  final InscriptionController inscriptionController;

  @override
  State<DashboardResultatsCompetitionPage> createState() =>
      _DashboardResultatsCompetitionPageState();
}

class _DashboardResultatsCompetitionPageState
    extends State<DashboardResultatsCompetitionPage> {
  bool _chargement = true;
  String? _erreur;
  List<_LigneResultat> _lignes = const [];
  String? _filtreEpreuveId;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await widget.epreuveController.charger(widget.competition.id);
      final lignes = <_LigneResultat>[];

      for (final epreuve in widget.epreuveController.epreuves) {
        await widget.mancheController.charger(epreuve.id);
        for (final manche in widget.mancheController.manches) {
          await widget.resultatController.charger(manche.id);
          lignes.addAll(
            widget.resultatController.resultats.map(
              (resultat) => _LigneResultat(
                epreuve: epreuve,
                manche: manche,
                resultat: resultat,
              ),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _lignes = lignes;
        _chargement = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = exception.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<_LigneResultat> get _lignesFiltrees {
    if (_filtreEpreuveId == null) return _lignes;
    return _lignes
        .where((ligne) => ligne.epreuve.id == _filtreEpreuveId)
        .toList(growable: false);
  }

  List<_ClassementAthlete> get _classement {
    final groupes = <String, _ClassementAthlete>{};
    for (final ligne in _lignesFiltrees) {
      final id = ligne.resultat.athlete.id;
      final actuel = groupes[id];
      groupes[id] = _ClassementAthlete(
        athleteId: id,
        nom: ligne.resultat.athlete.nomComplet,
        points: (actuel?.points ?? 0) + ligne.resultat.points,
        manches: (actuel?.manches ?? 0) + 1,
      );
    }
    final classement = groupes.values.toList()
      ..sort((a, b) {
        final points = b.points.compareTo(a.points);
        return points != 0 ? points : a.nom.compareTo(b.nom);
      });
    return classement;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard des résultats'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _chargement ? null : _charger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
          ? _ErreurDashboard(message: _erreur!, onReessayer: _charger)
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _FiltreEpreuve(
                    epreuves: widget.epreuveController.epreuves,
                    valeur: _filtreEpreuveId,
                    onChanged: (valeur) =>
                        setState(() => _filtreEpreuveId = valeur),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Classement cumulé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_classement.isEmpty)
                    const Text('Aucun résultat publié ou enregistré.')
                  else
                    ..._classement.asMap().entries.map(
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
                  if (_lignesFiltrees.isEmpty)
                    const Text('Aucun détail disponible.')
                  else
                    ..._lignesFiltrees.map(
                      (ligne) => _CarteDetail(ligne: ligne),
                    ),
                ],
              ),
            ),
    );
  }
}

class _LigneResultat {
  const _LigneResultat({
    required this.epreuve,
    required this.manche,
    required this.resultat,
  });
  final Epreuve epreuve;
  final Manche manche;
  final Resultat resultat;
}

class _ClassementAthlete {
  const _ClassementAthlete({
    required this.athleteId,
    required this.nom,
    required this.points,
    required this.manches,
  });
  final String athleteId;
  final String nom;
  final int points;
  final int manches;
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
  final _ClassementAthlete classement;

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
  final _LigneResultat ligne;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(ligne.resultat.athlete.nomComplet),
        subtitle: Text(
          '${ligne.epreuve.nom} • Manche ${ligne.manche.numero} • ${ligne.resultat.statut.name}',
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReessayer,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
