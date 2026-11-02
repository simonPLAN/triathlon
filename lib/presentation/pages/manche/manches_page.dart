import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/manche.dart';
import '../../controllers/manche_controller.dart';
import '../../widgets/manche/carte_manche.dart';
import '../../widgets/manche/erreur_manches.dart';
import '../../widgets/manche/liste_manches_vide.dart';
import 'detail_manche_page.dart';

class ManchesPage extends StatefulWidget {
  const ManchesPage({
    super.key,
    required this.competition,
    required this.epreuve,
    required this.controller,
  });

  final Competition competition;
  final Epreuve epreuve;
  final MancheController controller;

  @override
  State<ManchesPage> createState() {
    return _ManchesPageState();
  }
}

class _ManchesPageState extends State<ManchesPage> {
  MancheController get _controller {
    return widget.controller;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_actualiser);
    _controller.charger(widget.epreuve.id);
  }

  @override
  void didUpdateWidget(covariant ManchesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_actualiser);
      widget.controller.addListener(_actualiser);
    }

    if (oldWidget.epreuve.id != widget.epreuve.id) {
      widget.controller.charger(widget.epreuve.id);
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

  Future<void> _genererManches() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Générer les manches ?'),
          content: Text(
            '${widget.epreuve.nombreManches} manche(s) '
            'seront créées pour l’épreuve '
            '« ${widget.epreuve.nom} ».',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Générer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    final manches = await _controller.generer(widget.epreuve);

    if (!mounted) {
      return;
    }

    if (manches == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.erreur ?? 'Les manches n’ont pas pu être générées.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${manches.length} manche(s) générée(s).')),
    );
  }

  Future<void> _ouvrirDetail(Manche manche) async {
    final mancheActualisee = await Navigator.of(context).push<Manche>(
      MaterialPageRoute<Manche>(
        builder: (context) {
          return DetailManchePage(
            competition: widget.competition,
            epreuve: widget.epreuve,
            manche: manche,
            controller: _controller,
          );
        },
      ),
    );

    if (mancheActualisee == null || !mounted) {
      return;
    }

    _controller.remplacerLocalement(mancheActualisee);
  }

  @override
  Widget build(BuildContext context) {
    final generationAutorisee = widget.competition.estBrouillon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manches'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _controller.chargement
                ? null
                : () {
                    _controller.charger(widget.epreuve.id);
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: generationAutorisee && _controller.manches.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _controller.generationEnCours ? null : _genererManches,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Générer les manches'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteEpreuve(
              epreuve: widget.epreuve,
              generationAutorisee: generationAutorisee,
            ),
            Expanded(child: _construireContenu(generationAutorisee)),
          ],
        ),
      ),
    );
  }

  Widget _construireContenu(bool generationAutorisee) {
    if (_controller.chargement && _controller.manches.isEmpty) {
      return const _ChargementManches();
    }

    if (_controller.erreur != null && _controller.manches.isEmpty) {
      return ErreurManches(
        message: _controller.erreur!,
        onReessayer: () {
          return _controller.charger(widget.epreuve.id);
        },
      );
    }

    if (_controller.manches.isEmpty) {
      return ListeManchesVide(
        generationAutorisee: generationAutorisee,
        nombreManches: widget.epreuve.nombreManches,
        onGenerer: _genererManches,
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return _controller.charger(widget.epreuve.id);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _controller.manches.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final manche = _controller.manches[index];

          return CarteManche(
            manche: manche,
            onTap: () {
              _ouvrirDetail(manche);
            },
          );
        },
      ),
    );
  }
}

class _EnteteEpreuve extends StatelessWidget {
  const _EnteteEpreuve({
    required this.epreuve,
    required this.generationAutorisee,
  });

  final Epreuve epreuve;
  final bool generationAutorisee;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.sports_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  epreuve.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${epreuve.nombreManches} manche(s) prévues'
                  ' • ${epreuve.distanceMetres} m',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  generationAutorisee
                      ? 'Configuration autorisée'
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

class _ChargementManches extends StatelessWidget {
  const _ChargementManches();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des manches...'),
        ],
      ),
    );
  }
}
