import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/competition/carte_competition.dart';
import 'creer_competition_page.dart';
import 'detail_competition_page.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({
    super.key,
    required this.controller,
    required this.profilCoach,
  });

  final CompetitionController controller;
  final ProfilUtilisateur profilCoach;

  @override
  State<CompetitionsPage> createState() {
    return _CompetitionsPageState();
  }
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  CompetitionController get _controller {
    return widget.controller;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_actualiser);
    _controller.charger();
  }

  @override
  void didUpdateWidget(covariant CompetitionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_actualiser);
      widget.controller.addListener(_actualiser);
      widget.controller.charger();
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
    final competitionCreee = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return CreerCompetitionPage(
            controller: _controller,
            profilCoach: widget.profilCoach,
          );
        },
      ),
    );

    if (competitionCreee != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La compétition apparaît maintenant dans la liste.'),
      ),
    );
  }

  Future<void> _ouvrirDetail(Competition competition) async {
    final competitionSupprimee = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return DetailCompetitionPage(
            competition: competition,
            controller: _controller,
          );
        },
      ),
    );

    if (competitionSupprimee != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La compétition a été supprimée.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes compétitions'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _controller.chargement ? null : _controller.charger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.creationEnCours ? null : _ouvrirCreation,
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
      body: SafeArea(child: _construireContenu()),
    );
  }

  Widget _construireContenu() {
    if (_controller.chargement && _controller.competitions.isEmpty) {
      return const _ChargementCompetitions();
    }

    if (_controller.erreur != null && _controller.competitions.isEmpty) {
      return _ErreurCompetitions(
        message: _controller.erreur!,
        onReessayer: _controller.charger,
      );
    }

    if (_controller.competitions.isEmpty) {
      return _ListeCompetitionsVide(onCreer: _ouvrirCreation);
    }

    return RefreshIndicator(
      onRefresh: _controller.charger,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _controller.competitions.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final competition = _controller.competitions[index];

          return CarteCompetition(
            competition: competition,
            onTap: () => _ouvrirDetail(competition),
          );
        },
      ),
    );
  }
}

class _ChargementCompetitions extends StatelessWidget {
  const _ChargementCompetitions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des compétitions...'),
        ],
      ),
    );
  }
}

class _ErreurCompetitions extends StatelessWidget {
  const _ErreurCompetitions({required this.message, required this.onReessayer});

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
              'Impossible de charger les compétitions',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
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

class _ListeCompetitionsVide extends StatelessWidget {
  const _ListeCompetitionsVide({required this.onCreer});

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
              Icons.emoji_events_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune compétition',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crée ta première compétition pour '
              'commencer à configurer les épreuves '
              'et inscrire les athlètes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreer,
              icon: const Icon(Icons.add),
              label: const Text('Créer une compétition'),
            ),
          ],
        ),
      ),
    );
  }
}
