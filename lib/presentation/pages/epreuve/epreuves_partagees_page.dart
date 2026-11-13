import 'package:flutter/material.dart';

import '../../../application/use_cases/epreuve/gerer_partage_epreuve.dart';
import '../../../domain/entities/partage_epreuve.dart';
import '../../controllers/epreuve_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';
import '../../widgets/competition/badge_statut_competition.dart';
import '../manche/manches_page.dart';

class EpreuvesPartageesPage extends StatefulWidget {
  const EpreuvesPartageesPage({
    super.key,
    required this.partages,
    required this.epreuveController,
    required this.mancheController,
    required this.resultatController,
    required this.inscriptionController,
  });

  final GererPartageEpreuve partages;
  final EpreuveController epreuveController;
  final MancheController mancheController;
  final ResultatController resultatController;
  final InscriptionController inscriptionController;

  @override
  State<EpreuvesPartageesPage> createState() => _EpreuvesPartageesPageState();
}

class _EpreuvesPartageesPageState extends State<EpreuvesPartageesPage> {
  List<EpreuvePartagee> _epreuves = const [];
  String? _erreur;
  bool _chargement = true;

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
      final epreuves = await widget.partages.listerPartagees();
      if (mounted) setState(() => _epreuves = epreuves);
    } catch (_) {
      if (mounted) {
        setState(() {
          _epreuves = const [];
          _erreur = 'Impossible de vérifier tes accès. Réessaie.';
        });
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _ouvrir(EpreuvePartagee element) async {
    if (_chargement) return;
    // Chaque ouverture revérifie l’affectation, notamment après une révocation.
    await _charger();
    if (!mounted || _erreur != null) return;
    final actuelles = _epreuves.where(
      (e) => e.epreuve.id == element.epreuve.id,
    );
    if (actuelles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ton accès à cette épreuve a été retiré.'),
        ),
      );
      return;
    }
    final actuelle = actuelles.first;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ManchesPage(
          competition: actuelle.competition,
          epreuve: actuelle.epreuve,
          controller: widget.mancheController,
          resultatController: widget.resultatController,
          inscriptionController: widget.inscriptionController,
          affichesController: null,
          saisieDeleguee: true,
          partages: widget.partages,
        ),
      ),
    );
    if (mounted) {
      await _charger();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Épreuves partagées'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _chargement ? null : _charger,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Les épreuves pour lesquelles un responsable t’a autorisé à saisir les résultats.',
          ),
          const SizedBox(height: 16),
          if (_chargement) const LinearProgressIndicator(),
          if (_erreur != null) ...[
            Text(_erreur!),
            TextButton(
              onPressed: _chargement ? null : _charger,
              child: const Text('Réessayer'),
            ),
          ] else if (!_chargement && _epreuves.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('Aucune épreuve partagée pour le moment.'),
            ),
          for (final element in _epreuves)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.sports_outlined),
                title: Text(element.epreuve.nom),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(element.competition.nom),
                    Text(
                      '${element.epreuve.distanceMetres} m · ${element.epreuve.nombreManches} manche(s)',
                    ),
                    const SizedBox(height: 8),
                    BadgeStatutCompetition(statut: element.competition.statut),
                    const Text('Accès à la saisie des résultats'),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _chargement ? null : () => _ouvrir(element),
              ),
            ),
        ],
      ),
    ),
  );
}
