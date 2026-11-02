import 'package:flutter/material.dart';

import '../../widgets/inscription/inscrire_invite_dialog.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../controllers/inscription_controller.dart';
import '../../widgets/inscription/carte_inscription.dart';
import '../../widgets/inscription/modifier_dossard_dialog.dart';

class InscriptionsPage extends StatefulWidget {
  const InscriptionsPage({
    super.key,
    required this.competition,
    required this.controller,
  });

  final Competition competition;
  final InscriptionController controller;

  @override
  State<InscriptionsPage> createState() {
    return _InscriptionsPageState();
  }
}

class _InscriptionsPageState extends State<InscriptionsPage> {
  InscriptionController get _controller {
    return widget.controller;
  }

  bool get _modificationsAutorisees {
    return widget.competition.estBrouillon || widget.competition.estOuverte;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_actualiser);
    _controller.charger(competitionId: widget.competition.id);
  }

  @override
  void didUpdateWidget(covariant InscriptionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_actualiser);
      widget.controller.addListener(_actualiser);
    }

    if (oldWidget.competition.id != widget.competition.id) {
      widget.controller.charger(competitionId: widget.competition.id);
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

  Future<void> _modifierDossard(Inscription inscription) async {
    if (!_modificationsAutorisees || _controller.operationEnCours) {
      return;
    }

    final resultat = await showDialog<ResultatModificationDossard>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ModifierDossardDialog(inscription: inscription);
      },
    );

    if (resultat == null || !resultat.confirme || !mounted) {
      return;
    }

    final inscriptionActualisee = await _controller.modifierDossard(
      inscription: inscription,
      numeroDossard: resultat.numeroDossard,
    );

    if (!mounted) {
      return;
    }

    if (inscriptionActualisee == null) {
      _afficherErreur();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultat.numeroDossard == null
              ? 'Le dossard a été retiré.'
              : 'Le dossard a été enregistré.',
        ),
      ),
    );
  }

  Future<void> _desinscrire(Inscription inscription) async {
    if (!_modificationsAutorisees || _controller.operationEnCours) {
      return;
    }

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Désinscrire cet athlète ?'),
          content: Text(
            '${inscription.athlete.nomComplet} '
            'sera retiré de la compétition.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Désinscrire'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    final succes = await _controller.desinscrire(inscription);

    if (!mounted) {
      return;
    }

    if (!succes) {
      _afficherErreur();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('L’athlète a été désinscrit.')),
    );
  }

  void _afficherErreur() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.erreur ?? 'L’opération n’a pas pu être effectuée.',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _ajouterAthlete() async {
    if (!_modificationsAutorisees || _controller.operationEnCours) return;
    final succes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InscrireInviteDialog(
        competition: widget.competition,
        controller: _controller,
      ),
    );
    if (succes == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L’athlète invité a été inscrit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlètes inscrits'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _controller.operationEnCours
                ? null
                : _controller.recharger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _modificationsAutorisees
          ? FloatingActionButton.extended(
              onPressed: _controller.operationEnCours ? null : _ajouterAthlete,
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter un invité'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteInscriptions(
              competition: widget.competition,
              nombreInscriptions: _controller.inscriptions.length,
              modificationsAutorisees: _modificationsAutorisees,
            ),
            Expanded(child: _construireContenu()),
          ],
        ),
      ),
    );
  }

  Widget _construireContenu() {
    if (_controller.chargement && _controller.inscriptions.isEmpty) {
      return const _ChargementInscriptions();
    }

    if (_controller.erreur != null && _controller.inscriptions.isEmpty) {
      return _ErreurInscriptions(
        message: _controller.erreur!,
        onReessayer: _controller.recharger,
      );
    }

    if (_controller.inscriptions.isEmpty) {
      return _ListeInscriptionsVide(
        modificationsAutorisees: _modificationsAutorisees,
        onAjouter: _ajouterAthlete,
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.recharger,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _controller.inscriptions.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          final inscription = _controller.inscriptions[index];

          return CarteInscription(
            inscription: inscription,
            actionsActives:
                _modificationsAutorisees && !_controller.operationEnCours,
            onModifierDossard: () {
              _modifierDossard(inscription);
            },
            onDesinscrire: () {
              _desinscrire(inscription);
            },
          );
        },
      ),
    );
  }
}

class _EnteteInscriptions extends StatelessWidget {
  const _EnteteInscriptions({
    required this.competition,
    required this.nombreInscriptions,
    required this.modificationsAutorisees,
  });

  final Competition competition;
  final int nombreInscriptions;
  final bool modificationsAutorisees;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text(
                  '$nombreInscriptions '
                  '${nombreInscriptions > 1 ? 'athlètes inscrits' : 'athlète inscrit'}',
                ),
                if (!modificationsAutorisees) ...[
                  const SizedBox(height: 4),
                  const Text('Les inscriptions ne sont plus modifiables.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargementInscriptions extends StatelessWidget {
  const _ChargementInscriptions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des inscriptions...'),
        ],
      ),
    );
  }
}

class _ErreurInscriptions extends StatelessWidget {
  const _ErreurInscriptions({required this.message, required this.onReessayer});

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
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
}

class _ListeInscriptionsVide extends StatelessWidget {
  const _ListeInscriptionsVide({
    required this.modificationsAutorisees,
    required this.onAjouter,
  });

  final bool modificationsAutorisees;
  final VoidCallback onAjouter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun athlète inscrit',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              modificationsAutorisees
                  ? 'Ajoute les participants '
                        'à cette compétition.'
                  : 'Aucune inscription n’a été '
                        'enregistrée pour cette compétition.',
              textAlign: TextAlign.center,
            ),
            if (modificationsAutorisees) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAjouter,
                icon: const Icon(Icons.person_add),
                label: const Text('Inscrire un athlète'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
