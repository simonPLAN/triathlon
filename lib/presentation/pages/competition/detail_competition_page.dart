import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../widgets/competition/actions_statut_competition.dart';
import '../../widgets/competition/badge_statut_competition.dart';
import '../inscription/inscriptions_page.dart';
import 'modifier_competition_page.dart';

class DetailCompetitionPage extends StatefulWidget {
  const DetailCompetitionPage({
    super.key,
    required this.competition,
    required this.controller,
    required this.inscriptionController,
  });

  final Competition competition;
  final CompetitionController controller;
  final InscriptionController inscriptionController;

  @override
  State<DetailCompetitionPage> createState() {
    return _DetailCompetitionPageState();
  }
}

class _DetailCompetitionPageState extends State<DetailCompetitionPage> {
  late Competition _competition;

  @override
  void initState() {
    super.initState();
    _competition = widget.competition;
  }

  Future<void> _ouvrirInscriptions() async {
    widget.inscriptionController.reinitialiser();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return InscriptionsPage(
            competition: _competition,
            controller: widget.inscriptionController,
          );
        },
      ),
    );
  }

  Future<void> _supprimerCompetition() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la compétition ?'),
          content: Text(
            'La compétition « ${_competition.nom} » '
            'sera définitivement supprimée.',
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
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    final suppressionReussie = await widget.controller.supprimer(_competition);

    if (!mounted) {
      return;
    }

    if (!suppressionReussie) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.erreur ??
                'La compétition n’a pas pu être supprimée.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _ouvrirModification() async {
    final competitionModifiee = await Navigator.of(context).push<Competition>(
      MaterialPageRoute<Competition>(
        builder: (context) {
          return ModifierCompetitionPage(
            competition: _competition,
            controller: widget.controller,
          );
        },
      ),
    );

    if (competitionModifiee == null || !mounted) {
      return;
    }

    setState(() {
      _competition = competitionModifiee;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La compétition a été modifiée.')),
    );
  }

  String _messageChangementStatut(StatutCompetition statut) {
    switch (statut) {
      case StatutCompetition.brouillon:
        return 'La compétition est en brouillon.';

      case StatutCompetition.ouverte:
        return 'Les inscriptions sont maintenant ouvertes.';

      case StatutCompetition.enCours:
        return 'La compétition a démarré.';

      case StatutCompetition.terminee:
        return 'La compétition est terminée.';

      case StatutCompetition.annulee:
        return 'La compétition a été annulée.';
    }
  }

  Future<void> _changerStatut(StatutCompetition nouveauStatut) async {
    widget.controller.effacerErreur();

    final competitionActualisee = await widget.controller.changerStatut(
      competition: _competition,
      nouveauStatut: nouveauStatut,
    );

    if (!mounted) {
      return;
    }

    if (competitionActualisee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.erreur ?? 'Le statut n’a pas pu être modifié.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    setState(() {
      _competition = competitionActualisee;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_messageChangementStatut(competitionActualisee.statut)),
      ),
    );
  }

  void _fonctionnaliteEnPreparation(
    BuildContext context,
    String fonctionnalite,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fonctionnalite sera ajoutée prochainement.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la compétition'),
        actions: [
          IconButton(
            tooltip: _competition.estTerminee || _competition.estAnnulee
                ? 'Cette compétition ne peut plus être modifiée'
                : 'Modifier',
            onPressed:
                _competition.estTerminee ||
                    _competition.estAnnulee ||
                    widget.controller.changementStatutEnCours ||
                    widget.controller.suppressionEnCours
                ? null
                : _ouvrirModification,
            icon: const Icon(Icons.edit_outlined),
          ),
          if (_competition.estBrouillon)
            IconButton(
              tooltip: 'Supprimer',
              onPressed:
                  widget.controller.suppressionEnCours ||
                      widget.controller.changementStatutEnCours
                  ? null
                  : _supprimerCompetition,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _EnteteCompetition(competition: _competition),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                return ActionsStatutCompetition(
                  competition: _competition,
                  changementEnCours: widget.controller.changementStatutEnCours,
                  onChangerStatut: _changerStatut,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Informations générales',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _InformationsGenerales(competition: _competition),
            const SizedBox(height: 24),
            Text('Organisation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ActionsCompetition(
              onVoirAthletes: _ouvrirInscriptions,
              onVoirEpreuves: () {
                _fonctionnaliteEnPreparation(
                  context,
                  'La gestion des épreuves',
                );
              },
              onVoirManches: () {
                _fonctionnaliteEnPreparation(context, 'La gestion des manches');
              },
              onVoirResultats: () {
                _fonctionnaliteEnPreparation(
                  context,
                  'La gestion des résultats',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EnteteCompetition extends StatelessWidget {
  const _EnteteCompetition({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    competition.nom,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BadgeStatutCompetition(statut: competition.statut),
          ],
        ),
      ),
    );
  }
}

class _InformationsGenerales extends StatelessWidget {
  const _InformationsGenerales({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _LigneInformation(
            icone: Icons.calendar_today_outlined,
            titre: 'Date',
            valeur: _formaterDate(competition.dateCompetition),
          ),
          const Divider(height: 1),
          _LigneInformation(
            icone: Icons.location_on_outlined,
            titre: 'Lieu',
            valeur: _texteOuValeurParDefaut(
              competition.lieu,
              'Lieu non renseigné',
            ),
          ),
          const Divider(height: 1),
          _LigneInformation(
            icone: Icons.description_outlined,
            titre: 'Description',
            valeur: _texteOuValeurParDefaut(
              competition.description,
              'Aucune description',
            ),
          ),
          const Divider(height: 1),
          _LigneInformation(
            icone: Icons.update_outlined,
            titre: 'Dernière modification',
            valeur: _formaterDateEtHeure(competition.dateModification),
          ),
        ],
      ),
    );
  }

  String _texteOuValeurParDefaut(String? valeur, String valeurParDefaut) {
    final valeurNettoyee = valeur?.trim();

    if (valeurNettoyee == null || valeurNettoyee.isEmpty) {
      return valeurParDefaut;
    }

    return valeurNettoyee;
  }

  String _formaterDate(DateTime date) {
    const mois = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${date.day} '
        '${mois[date.month - 1]} '
        '${date.year}';
  }

  String _formaterDateEtHeure(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year} à $heure:$minute';
  }
}

class _LigneInformation extends StatelessWidget {
  const _LigneInformation({
    required this.icone,
    required this.titre,
    required this.valeur,
  });

  final IconData icone;
  final String titre;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: Theme.of(context).colorScheme.primary),
      title: Text(titre),
      subtitle: Text(valeur),
    );
  }
}

class _ActionsCompetition extends StatelessWidget {
  const _ActionsCompetition({
    required this.onVoirAthletes,
    required this.onVoirEpreuves,
    required this.onVoirManches,
    required this.onVoirResultats,
  });

  final VoidCallback onVoirAthletes;
  final VoidCallback onVoirEpreuves;
  final VoidCallback onVoirManches;
  final VoidCallback onVoirResultats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final nombreColonnes = contraintes.maxWidth >= 700 ? 4 : 2;

        return GridView.count(
          crossAxisCount: nombreColonnes,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _CarteActionCompetition(
              titre: 'Athlètes',
              description: 'Gérer les inscriptions',
              icone: Icons.groups_outlined,
              couleur: Colors.blue,
              onTap: onVoirAthletes,
            ),
            _CarteActionCompetition(
              titre: 'Épreuves',
              description: 'Configurer les disciplines',
              icone: Icons.directions_run_outlined,
              couleur: Colors.orange,
              onTap: onVoirEpreuves,
            ),
            _CarteActionCompetition(
              titre: 'Manches',
              description: 'Organiser les départs',
              icone: Icons.timer_outlined,
              couleur: Colors.green,
              onTap: onVoirManches,
            ),
            _CarteActionCompetition(
              titre: 'Résultats',
              description: 'Consulter le classement',
              icone: Icons.leaderboard_outlined,
              couleur: Colors.purple,
              onTap: onVoirResultats,
            ),
          ],
        );
      },
    );
  }
}

class _CarteActionCompetition extends StatelessWidget {
  const _CarteActionCompetition({
    required this.titre,
    required this.description,
    required this.icone,
    required this.couleur,
    required this.onTap,
  });

  final String titre;
  final String description;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 38, color: couleur),
              const SizedBox(height: 10),
              Text(
                titre,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
