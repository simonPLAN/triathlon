import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/epreuve.dart';
import '../../controllers/epreuve_controller.dart';
import '../../widgets/epreuve/formulaire_epreuve.dart';

class CreerEpreuvePage extends StatefulWidget {
  const CreerEpreuvePage({
    super.key,
    required this.competition,
    required this.controller,
  });

  final Competition competition;
  final EpreuveController controller;

  @override
  State<CreerEpreuvePage> createState() => _CreerEpreuvePageState();
}

class _CreerEpreuvePageState extends State<CreerEpreuvePage> {
  Epreuve? _epreuveCreee;
  bool _envoiAffiches = false;
  String? _erreurAffiches;

  bool get _operationEnCours =>
      widget.controller.creationEnCours ||
      _envoiAffiches ||
      (widget.controller.affiches?.operationEnCours ?? false);

  @override
  void initState() {
    super.initState();
    widget.controller.affiches?.reinitialiser();
  }

  Future<void> _creerEpreuve(
    BuildContext context,
    DonneesFormulaireEpreuve donnees,
  ) async {
    if (_operationEnCours) return;
    widget.controller.effacerErreur();
    setState(() {
      _envoiAffiches = true;
      _erreurAffiches = null;
    });

    try {
      var epreuve = _epreuveCreee;
      if (epreuve == null) {
        epreuve = await widget.controller.creer(
          competitionId: widget.competition.id,
          discipline: donnees.discipline,
          nom: donnees.nom,
          distanceMetres: donnees.distanceMetres,
          nombreManches: donnees.nombreManches,
          ordre: donnees.ordre,
          dureeLimiteSecondes: donnees.dureeLimiteSecondes,
        );
        if (!mounted) return;
        if (epreuve == null) {
          _afficherErreur(
            widget.controller.erreur ?? 'L’épreuve n’a pas pu être créée.',
          );
          return;
        }
        setState(() => _epreuveCreee = epreuve);
      }

      final affiches = widget.controller.affiches;
      if (affiches != null) {
        for (var index = 0; index < donnees.affiches.length; index++) {
          final position = index + 1;
          if (affiches.affiches.any((a) => a.position == position)) continue;
          final attente = donnees.affiches[index];
          final succes = await affiches.ajouterFichier(
            epreuveId: epreuve.id,
            position: position,
            texteAlternatif: attente.texteAlternatif,
            fichier: attente.fichier,
          );
          if (!mounted) return;
          if (!succes) {
            setState(() {
              _erreurAffiches =
                  affiches.erreur ??
                  'L’épreuve est créée, mais une affiche n’a pas été envoyée.';
            });
            return;
          }
        }
      }

      if (context.mounted) Navigator.of(context).pop(epreuve);
    } finally {
      if (mounted) setState(() => _envoiAffiches = false);
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return PopScope(
          canPop: !_operationEnCours,
          child: Scaffold(
            appBar: AppBar(title: const Text('Créer une épreuve')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EnteteCreationEpreuve(
                          nomCompetition: widget.competition.nom,
                        ),
                        if (_epreuveCreee != null) ...[
                          const SizedBox(height: 16),
                          Material(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'L’épreuve est créée. Les informations principales sont verrouillées pendant la reprise de l’envoi des affiches.',
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (widget.controller.erreur != null) ...[
                          _MessageErreurEpreuve(
                            message: widget.controller.erreur!,
                            onFermer: widget.controller.effacerErreur,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_erreurAffiches != null) ...[
                          _MessageErreurEpreuve(
                            message: _erreurAffiches!,
                            onFermer: () =>
                                setState(() => _erreurAffiches = null),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FormulaireEpreuve(
                          ordreInitial: widget.controller.prochainOrdre(),
                          enregistrementEnCours: _operationEnCours,
                          champsPrincipauxActifs: _epreuveCreee == null,
                          affichesController: widget.controller.affiches,
                          libelleBouton: _epreuveCreee == null
                              ? 'Créer l’épreuve'
                              : 'Réessayer l’envoi',
                          onValider: (donnees) {
                            return _creerEpreuve(context, donnees);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnteteCreationEpreuve extends StatelessWidget {
  const _EnteteCreationEpreuve({required this.nomCompetition});

  final String nomCompetition;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.sports_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouvelle épreuve',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nomCompetition,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageErreurEpreuve extends StatelessWidget {
  const _MessageErreurEpreuve({required this.message, required this.onFermer});

  final String message;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Material(
      color: couleurs.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: couleurs.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: couleurs.onErrorContainer),
              ),
            ),
            IconButton(
              tooltip: 'Fermer le message',
              onPressed: onFermer,
              icon: Icon(Icons.close, color: couleurs.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
