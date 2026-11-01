import 'package:flutter/material.dart';

import '../../../application/use_cases/deconnecter_utilisateur.dart';
import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../controllers/competitions_ouvertes_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../widgets/competition/badge_statut_competition.dart';

class AthleteDashboardPage extends StatefulWidget {
  const AthleteDashboardPage({
    super.key,
    required this.profil,
    required this.competitionsController,
    required this.inscriptionController,
    required this.deconnecterUtilisateur,
  });

  final ProfilUtilisateur profil;

  final CompetitionsOuvertesController competitionsController;

  final InscriptionController inscriptionController;

  final DeconnecterUtilisateur deconnecterUtilisateur;

  @override
  State<AthleteDashboardPage> createState() {
    return _AthleteDashboardPageState();
  }
}

class _AthleteDashboardPageState extends State<AthleteDashboardPage> {
  CompetitionsOuvertesController get _competitionsController {
    return widget.competitionsController;
  }

  InscriptionController get _inscriptionController {
    return widget.inscriptionController;
  }

  Future<void> _desinscrire(
    Competition competition,
    Inscription inscription,
  ) async {
    if (_inscriptionController.desinscriptionEnCours) {
      return;
    }

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la désinscription'),
          content: Text(
            'Souhaites-tu te désinscrire de la compétition '
            '« ${competition.nom} » ?',
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
              label: const Text('Se désinscrire'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    final succes = await _inscriptionController.desinscrire(inscription);

    if (!mounted) {
      return;
    }

    if (!succes) {
      _afficherErreur(
        _inscriptionController.erreur ??
            'La désinscription n’a pas pu être effectuée.',
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tu es désinscrit de « ${competition.nom} ».')),
    );
  }

  @override
  void initState() {
    super.initState();

    _competitionsController.addListener(_actualiser);

    _inscriptionController.addListener(_actualiser);

    _chargerCompetitionsEtInscriptions();
  }

  @override
  void dispose() {
    _competitionsController.removeListener(_actualiser);

    _inscriptionController.removeListener(_actualiser);

    super.dispose();
  }

  void _actualiser() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _chargerCompetitionsEtInscriptions() async {
    await _competitionsController.charger();

    if (!mounted) {
      return;
    }

    await _inscriptionController.verifierInscriptionsUtilisateur(
      _competitionsController.competitions,
    );
  }

  Future<void> _recharger() async {
    _inscriptionController.reinitialiserInscriptionsUtilisateur();

    await _competitionsController.recharger();

    if (!mounted) {
      return;
    }

    await _inscriptionController.verifierInscriptionsUtilisateur(
      _competitionsController.competitions,
    );
  }

  Future<void> _deconnecter() async {
    try {
      await widget.deconnecterUtilisateur.executer();
    } catch (exception) {
      if (!mounted) {
        return;
      }

      _afficherErreur(_nettoyerMessageErreur(exception));
    }
  }

  Future<void> _inscrire(Competition competition) async {
    if (_inscriptionController.inscriptionEnCours) {
      return;
    }

    if (_inscriptionController.estInscritA(competition.id)) {
      return;
    }

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer l’inscription'),
          content: Text(
            'Souhaites-tu t’inscrire à la compétition '
            '« ${competition.nom} » ?',
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
              icon: const Icon(Icons.how_to_reg),
              label: const Text('S’inscrire'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    final inscription = await _inscriptionController
        .inscrireUtilisateurConnecte(competition: competition);

    if (!mounted) {
      return;
    }

    if (inscription == null) {
      _afficherErreur(
        _inscriptionController.erreur ??
            'L’inscription n’a pas pu être effectuée.',
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Inscription confirmée pour '
          '« ${competition.nom} ».',
        ),
      ),
    );
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _nettoyerMessageErreur(Object exception) {
    return exception
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace athlète'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _competitionsController.chargement ? null : _recharger,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: _deconnecter,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteAthlete(profil: widget.profil),
            Expanded(child: _construireContenu()),
          ],
        ),
      ),
    );
  }

  Widget _construireContenu() {
    if (_competitionsController.chargement &&
        _competitionsController.competitions.isEmpty) {
      return const _ChargementCompetitions();
    }

    if (_competitionsController.erreur != null &&
        _competitionsController.competitions.isEmpty) {
      return _ErreurCompetitions(
        message: _competitionsController.erreur!,
        onReessayer: _recharger,
      );
    }

    if (_competitionsController.competitions.isEmpty) {
      return const _AucuneCompetitionOuverte();
    }

    return RefreshIndicator(
      onRefresh: _recharger,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _competitionsController.competitions.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final competition = _competitionsController.competitions[index];

          final inscription = _inscriptionController.inscriptionUtilisateurPour(
            competition.id,
          );

          final verificationEnCours = _inscriptionController
              .verificationEnCoursPour(competition.id);

          final verificationEffectuee = _inscriptionController
              .inscriptionUtilisateurVerifiee(competition.id);

          return _CarteCompetitionAthlete(
            competition: competition,
            inscription: inscription,
            verificationEnCours: verificationEnCours,
            verificationEffectuee: verificationEffectuee,
            inscriptionEnCours: _inscriptionController.inscriptionEnCours,
            desinscriptionEnCours: _inscriptionController.desinscriptionEnCours,
            onInscrire: () {
              _inscrire(competition);
            },
            onDesinscrire: inscription == null
                ? null
                : () {
                    _desinscrire(competition, inscription);
                  },
          );
        },
      ),
    );
  }
}

class _EnteteAthlete extends StatelessWidget {
  const _EnteteAthlete({required this.profil});

  final ProfilUtilisateur profil;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(child: Text(_initiales)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ${profil.prenom}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Compétitions ouvertes '
                  'aux inscriptions',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _initiales {
    final initialePrenom = profil.prenom.isEmpty ? '' : profil.prenom[0];

    final initialeNom = profil.nom.isEmpty ? '' : profil.nom[0];

    return '$initialePrenom$initialeNom'.toUpperCase();
  }
}

class _CarteCompetitionAthlete extends StatelessWidget {
  const _CarteCompetitionAthlete({
    required this.competition,
    required this.inscription,
    required this.verificationEnCours,
    required this.verificationEffectuee,
    required this.inscriptionEnCours,
    required this.desinscriptionEnCours,
    required this.onInscrire,
    required this.onDesinscrire,
  });

  final Competition competition;
  final Inscription? inscription;
  final bool verificationEnCours;
  final bool verificationEffectuee;
  final bool inscriptionEnCours;
  final bool desinscriptionEnCours;
  final VoidCallback onInscrire;
  final VoidCallback? onDesinscrire;

  @override
  Widget build(BuildContext context) {
    final possedeLieu =
        competition.lieu != null && competition.lieu!.trim().isNotEmpty;

    final possedeDescription =
        competition.description != null &&
        competition.description!.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 38,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    competition.nom,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                BadgeStatutCompetition(statut: competition.statut),
              ],
            ),
            const SizedBox(height: 16),
            _InformationCompetition(
              icone: Icons.calendar_today_outlined,
              texte: _formaterDate(competition.dateCompetition),
            ),
            if (possedeLieu) ...[
              const SizedBox(height: 10),
              _InformationCompetition(
                icone: Icons.location_on_outlined,
                texte: competition.lieu!.trim(),
              ),
            ],
            if (possedeDescription) ...[
              const SizedBox(height: 12),
              Text(
                competition.description!.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            _SectionInscriptionAthlete(
              inscription: inscription,
              verificationEnCours: verificationEnCours,
              verificationEffectuee: verificationEffectuee,
              inscriptionEnCours: inscriptionEnCours,
              desinscriptionEnCours: desinscriptionEnCours,
              onInscrire: onInscrire,
              onDesinscrire: onDesinscrire,
            ),
          ],
        ),
      ),
    );
  }

  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');

    final mois = date.month.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year}';
  }
}

class _SectionInscriptionAthlete extends StatelessWidget {
  const _SectionInscriptionAthlete({
    required this.inscription,
    required this.verificationEnCours,
    required this.verificationEffectuee,
    required this.inscriptionEnCours,
    required this.desinscriptionEnCours,
    required this.onInscrire,
    required this.onDesinscrire,
  });

  final Inscription? inscription;
  final bool verificationEnCours;
  final bool verificationEffectuee;
  final bool inscriptionEnCours;
  final bool desinscriptionEnCours;
  final VoidCallback onInscrire;
  final VoidCallback? onDesinscrire;

  @override
  Widget build(BuildContext context) {
    if (verificationEnCours || !verificationEffectuee) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('Vérification de l’inscription...'),
        ),
      );
    }

    final inscriptionActuelle = inscription;

    if (inscriptionActuelle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Déjà inscrit',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inscriptionActuelle.numeroDossard == null
                            ? 'Dossard non attribué'
                            : 'Dossard n°'
                                  '${inscriptionActuelle.numeroDossard}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: desinscriptionEnCours ? null : onDesinscrire,
            icon: desinscriptionEnCours
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_remove_outlined),
            label: Text(
              desinscriptionEnCours ? 'Désinscription...' : 'Se désinscrire',
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: inscriptionEnCours ? null : onInscrire,
        icon: inscriptionEnCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.how_to_reg),
        label: Text(inscriptionEnCours ? 'Inscription...' : 'S’inscrire'),
      ),
    );
  }
}

class _InformationCompetition extends StatelessWidget {
  const _InformationCompetition({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(texte)),
      ],
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
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
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
}

class _AucuneCompetitionOuverte extends StatelessWidget {
  const _AucuneCompetitionOuverte();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Aucune compétition ouverte '
              'aux inscriptions.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
