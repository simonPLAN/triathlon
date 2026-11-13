import 'package:flutter/material.dart';

import '../../../application/use_cases/epreuve/gerer_partage_epreuve.dart';

import '../../widgets/commun/bouton_action_principale.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/manche.dart';
import '../../controllers/affiches_epreuve_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';
import '../../widgets/manche/carte_manche.dart';
import '../../widgets/manche/erreur_manches.dart';
import '../../widgets/manche/liste_manches_vide.dart';
import '../../widgets/epreuve/galerie_affiches_epreuve.dart';
import 'detail_manche_page.dart';

class ManchesPage extends StatefulWidget {
  const ManchesPage({
    super.key,
    required this.competition,
    required this.epreuve,
    required this.controller,
    required this.resultatController,
    required this.inscriptionController,
    this.affichesController,
    this.saisieDeleguee = false,
    this.partages,
  });

  final Competition competition;
  final Epreuve epreuve;
  final MancheController controller;
  final ResultatController resultatController;
  final InscriptionController inscriptionController;
  final AffichesEpreuveController? affichesController;
  final bool saisieDeleguee;
  final GererPartageEpreuve? partages;

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
    _chargerEtGenererSiNecessaire();
  }

  @override
  void didUpdateWidget(covariant ManchesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_actualiser);
      widget.controller.addListener(_actualiser);
    }

    if (oldWidget.epreuve.id != widget.epreuve.id) {
      _chargerEtGenererSiNecessaire();
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

  Future<void> _chargerEtGenererSiNecessaire() async {
    await _controller.charger(widget.epreuve.id);

    if (!mounted ||
        !widget.competition.estBrouillon ||
        _controller.manches.isNotEmpty ||
        _controller.generationEnCours) {
      return;
    }

    await _controller.generer(widget.epreuve);
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

  Future<void> _publierTousLesResultats() async {
    if (_controller.actionEnCours || _controller.chargement) return;
    final nombre = _controller.manches
        .where((m) => m.peutPublierResultats)
        .length;
    if (nombre == 0) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publier tous les résultats ?'),
        content: Text(
          'Les résultats de $nombre manche(s) terminée(s) seront visibles '
          'par les athlètes inscrits. Les manches en cours ou à venir '
          'ne seront pas publiées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final nombrePublie = await _controller.publierTousLesResultats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nombrePublie == null
              ? _controller.erreur ?? 'La publication a échoué.'
              : '$nombrePublie manche(s) publiée(s).',
        ),
      ),
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
            resultatController: widget.resultatController,
            inscriptionController: widget.inscriptionController,
            saisieDeleguee: widget.saisieDeleguee,
            partages: widget.partages,
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
    final generationAutorisee =
        !widget.saisieDeleguee && widget.competition.estBrouillon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manches'),
        actions: [
          if (widget.affichesController != null)
            IconButton(
              tooltip: 'Voir les affiches',
              onPressed: () => ouvrirGalerieAffichesEpreuve(
                context: context,
                epreuveId: widget.epreuve.id,
                controller: widget.affichesController!,
                titre: 'Affiches — ${widget.epreuve.nom}',
              ),
              icon: const Icon(Icons.image_outlined),
            ),
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
      bottomNavigationBar: widget.saisieDeleguee || _controller.manches.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _controller.manches.any((m) => m.peutPublierResultats)
                          ? 'Publier les résultats des manches terminées de cette épreuve.'
                          : _controller.manches.any((m) => m.resultatsPublies)
                          ? 'Tous les résultats disponibles sont publiés.'
                          : _controller.manches.any((m) => m.estTerminee)
                          ? 'Valide les classements depuis le détail de chaque manche avant publication.'
                          : 'Termine une manche pour publier ses résultats.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    BoutonActionPrincipale(
                      enCours: _controller.actionEnCours,
                      onPressed:
                          _controller.actionEnCours ||
                              _controller.chargement ||
                              _controller.generationEnCours ||
                              !_controller.manches.any(
                                (m) => m.peutPublierResultats,
                              )
                          ? null
                          : _publierTousLesResultats,
                      icone: Icons.publish_outlined,
                      libelle: 'Publier tous les résultats',
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteEpreuve(
              epreuve: widget.epreuve,
              generationAutorisee: generationAutorisee,
            ),
            if (widget.saisieDeleguee)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.secondaryContainer,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Accès délégué : consultation des manches et saisie des résultats.',
                  textAlign: TextAlign.center,
                ),
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
