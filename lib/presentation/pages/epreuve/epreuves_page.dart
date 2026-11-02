import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../controllers/epreuve_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../widgets/epreuve/carte_epreuve.dart';
import '../../widgets/epreuve/creer_epreuve_page.dart';
import '../manche/manches_page.dart';

class EpreuvesPage extends StatefulWidget {
  const EpreuvesPage({
    super.key,
    required this.competition,
    required this.controller,
    required this.mancheController,
  });

  final Competition competition;
  final EpreuveController controller;
  final MancheController mancheController;

  @override
  State<EpreuvesPage> createState() {
    return _EpreuvesPageState();
  }
}

class _EpreuvesPageState extends State<EpreuvesPage> {
  EpreuveController get _controller {
    return widget.controller;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_actualiser);
    _controller.charger(widget.competition.id);
  }

  @override
  void didUpdateWidget(covariant EpreuvesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_actualiser);
      widget.controller.addListener(_actualiser);
    }

    if (oldWidget.competition.id != widget.competition.id) {
      widget.controller.charger(widget.competition.id);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_actualiser);
    super.dispose();
  }

  void _actualiser() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _ouvrirCreation() async {
    final epreuveCreee = await Navigator.of(context).push<Epreuve>(
      MaterialPageRoute<Epreuve>(
        builder: (context) {
          return CreerEpreuvePage(
            competition: widget.competition,
            controller: _controller,
          );
        },
      ),
    );

    if (epreuveCreee == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'L’épreuve « ${epreuveCreee.nom} » '
          'a été créée.',
        ),
      ),
    );
  }

  Future<void> _ouvrirEpreuve(Epreuve epreuve) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return ManchesPage(
            competition: widget.competition,
            epreuve: epreuve,
            controller: widget.mancheController,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peutModifier = widget.competition.estBrouillon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Épreuves'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _controller.chargement ? null : _controller.recharger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: peutModifier
          ? FloatingActionButton.extended(
              onPressed: _controller.creationEnCours ? null : _ouvrirCreation,
              icon: const Icon(Icons.add),
              label: const Text('Créer une épreuve'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteCompetition(
              competition: widget.competition,
              modificationAutorisee: peutModifier,
            ),
            Expanded(child: _construireContenu()),
          ],
        ),
      ),
    );
  }

  Widget _construireContenu() {
    if (_controller.chargement && _controller.epreuves.isEmpty) {
      return const _ChargementEpreuves();
    }

    if (_controller.erreur != null && _controller.epreuves.isEmpty) {
      return _ErreurEpreuves(
        message: _controller.erreur!,
        onReessayer: () {
          return _controller.charger(widget.competition.id);
        },
      );
    }

    if (_controller.epreuves.isEmpty) {
      return _ListeEpreuvesVide(
        creationAutorisee: widget.competition.estBrouillon,
        onCreer: _ouvrirCreation,
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return _controller.charger(widget.competition.id);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _controller.epreuves.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final epreuve = _controller.epreuves[index];

          return CarteEpreuve(
            epreuve: epreuve,
            onTap: () {
              _ouvrirEpreuve(epreuve);
            },
          );
        },
      ),
    );
  }
}

class _EnteteCompetition extends StatelessWidget {
  const _EnteteCompetition({
    required this.competition,
    required this.modificationAutorisee,
  });

  final Competition competition;
  final bool modificationAutorisee;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competition.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  modificationAutorisee
                      ? 'Configuration des épreuves'
                      : 'Consultation uniquement',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargementEpreuves extends StatelessWidget {
  const _ChargementEpreuves();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des épreuves...'),
        ],
      ),
    );
  }
}

class _ErreurEpreuves extends StatelessWidget {
  const _ErreurEpreuves({required this.message, required this.onReessayer});

  final String message;
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les épreuves',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await onReessayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeEpreuvesVide extends StatelessWidget {
  const _ListeEpreuvesVide({
    required this.creationAutorisee,
    required this.onCreer,
  });

  final bool creationAutorisee;
  final VoidCallback onCreer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune épreuve',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              creationAutorisee
                  ? 'Ajoute une première épreuve '
                        'pour configurer les disciplines '
                        'et les manches.'
                  : 'Aucune épreuve n’a été configurée '
                        'pour cette compétition.',
              textAlign: TextAlign.center,
            ),
            if (creationAutorisee) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreer,
                icon: const Icon(Icons.add),
                label: const Text('Créer une épreuve'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
