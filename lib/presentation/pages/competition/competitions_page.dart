import 'package:flutter/material.dart';

import '../../widgets/commun/etat_vide.dart';
import '../../widgets/commun/message_erreur.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/epreuve_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../controllers/manche_controller.dart';
import '../../controllers/resultat_controller.dart';
import '../../widgets/competition/carte_competition.dart';
import 'creer_competition_page.dart';
import 'detail_competition_page.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({
    super.key,
    required this.controller,
    required this.inscriptionController,
    required this.profilCoach,
    required this.epreuveController,
    required this.mancheController,
    required this.resultatController,
  });

  final CompetitionController controller;
  final InscriptionController inscriptionController;
  final ProfilUtilisateur profilCoach;
  final EpreuveController epreuveController;
  final MancheController mancheController;
  final ResultatController resultatController;

  @override
  State<CompetitionsPage> createState() {
    return _CompetitionsPageState();
  }
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  StatutCompetition? _statutSelectionne;

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
            inscriptionController: widget.inscriptionController,
            epreuveController: widget.epreuveController,
            mancheController: widget.mancheController,
            resultatController: widget.resultatController,
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

  List<Competition> get _competitionsFiltrees {
    final statut = _statutSelectionne;

    if (statut == null) {
      return _controller.competitions;
    }

    return _controller.competitions
        .where((competition) => competition.statut == statut)
        .toList(growable: false);
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

    final competitions = _competitionsFiltrees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FiltresStatutCompetition(
          statutSelectionne: _statutSelectionne,
          onSelectionne: (statut) {
            setState(() {
              _statutSelectionne = statut;
            });
          },
        ),
        Expanded(
          child: competitions.isEmpty
              ? _AucuneCompetitionPourFiltre(
                  onEffacer: () {
                    setState(() {
                      _statutSelectionne = null;
                    });
                  },
                )
              : RefreshIndicator(
                  onRefresh: _controller.charger,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: competitions.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 12);
                    },
                    itemBuilder: (context, index) {
                      final competition = competitions[index];

                      return CarteCompetition(
                        competition: competition,
                        onTap: () => _ouvrirDetail(competition),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FiltresStatutCompetition extends StatelessWidget {
  const _FiltresStatutCompetition({
    required this.statutSelectionne,
    required this.onSelectionne,
  });

  final StatutCompetition? statutSelectionne;
  final ValueChanged<StatutCompetition?> onSelectionne;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Toutes'),
            selected: statutSelectionne == null,
            onSelected: (_) => onSelectionne(null),
          ),
          for (final statut in StatutCompetition.values) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(_libelleStatut(statut)),
              selected: statutSelectionne == statut,
              onSelected: (_) => onSelectionne(statut),
            ),
          ],
        ],
      ),
    );
  }

  String _libelleStatut(StatutCompetition statut) {
    return switch (statut) {
      StatutCompetition.brouillon => 'Brouillons',
      StatutCompetition.ouverte => 'Ouvertes',
      StatutCompetition.enCours => 'En cours',
      StatutCompetition.terminee => 'Terminées',
      StatutCompetition.annulee => 'Annulées',
    };
  }
}

class _AucuneCompetitionPourFiltre extends StatelessWidget {
  const _AucuneCompetitionPourFiltre({required this.onEffacer});
  final VoidCallback onEffacer;

  @override
  Widget build(BuildContext context) => EtatVide(
    titre: 'Aucune compétition pour ce filtre',
    description: 'Choisis un autre statut pour retrouver tes compétitions.',
    icone: Icons.filter_alt_off_outlined,
    libelleAction: 'Afficher toutes',
    onAction: onEffacer,
  );
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
  Widget build(BuildContext context) => MessageErreur(
    titre: 'Impossible de charger les compétitions',
    message: message,
    onReessayer: onReessayer,
  );
}

class _ListeCompetitionsVide extends StatelessWidget {
  const _ListeCompetitionsVide({required this.onCreer});
  final VoidCallback onCreer;

  @override
  Widget build(BuildContext context) => EtatVide(
    titre: 'Aucune compétition',
    description: 'Crée ta première compétition pour configurer les épreuves et inscrire les athlètes.',
    icone: Icons.emoji_events_outlined,
    libelleAction: 'Créer une compétition',
    onAction: onCreer,
  );
}
