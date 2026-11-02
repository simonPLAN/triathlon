import 'package:flutter/material.dart';

import 'resultats_athlete_page.dart';

import '../../../application/use_cases/deconnecter_utilisateur.dart';
import '../../../domain/entities/competition.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../controllers/competitions_ouvertes_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../widgets/athlete/carte_competition_athlete.dart';

class AthleteDashboardPage extends StatefulWidget {
  const AthleteDashboardPage({
    super.key,
    required this.profil,
    this.onMonCompte,
    required this.competitionsController,
    required this.inscriptionController,
    required this.deconnecterUtilisateur,
  });

  final ProfilUtilisateur profil;
  final VoidCallback? onMonCompte;

  final CompetitionsOuvertesController competitionsController;

  final InscriptionController inscriptionController;

  final DeconnecterUtilisateur deconnecterUtilisateur;

  @override
  State<AthleteDashboardPage> createState() {
    return _AthleteDashboardPageState();
  }
}

class _AthleteDashboardPageState extends State<AthleteDashboardPage>
    with WidgetsBindingObserver {
  bool _actualisationEnCours = false;
  bool _mesCompetitions = true;
  List<Competition> get _competitionsAffichees => _mesCompetitions
      ? _competitionsController.inscrites
      : _competitionsController.competitions;

  List<Competition> get _toutesCompetitions => {
    for (final c in _competitionsController.competitions) c.id: c,
    for (final c in _competitionsController.inscrites) c.id: c,
  }.values.toList();

  void _ouvrirResultats(Competition competition) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ResultatsAthletePage(
          competition: competition,
          controller: _competitionsController,
          athleteId: widget.profil.id,
        ),
      ),
    );
  }

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

    final succes = await _inscriptionController.desinscrire(
      inscription,
      competition: competition,
    );

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

    _competitionsController.actualiserInscription(competition, inscrite: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tu es désinscrit de « ${competition.nom} ».')),
    );
    await _competitionsController.recharger();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _competitionsController.addListener(_actualiser);

    _inscriptionController.addListener(_actualiser);

    _chargerCompetitionsEtInscriptions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _competitionsController.removeListener(_actualiser);

    _inscriptionController.removeListener(_actualiser);

    super.dispose();
  }

  void _actualiser() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recharger();
  }

  Future<void> _chargerCompetitionsEtInscriptions() async {
    if (_actualisationEnCours) return;
    _actualisationEnCours = true;
    try {
      await _competitionsController.charger();
      if (!mounted) return;
      await _inscriptionController.verifierInscriptionsUtilisateur(
        _toutesCompetitions,
      );
    } finally {
      _actualisationEnCours = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _recharger() => _chargerCompetitionsEtInscriptions();

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

    _competitionsController.actualiserInscription(competition, inscrite: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Inscription confirmée pour '
          '« ${competition.nom} ».',
        ),
      ),
    );
    await _competitionsController.recharger();
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
            tooltip: 'Supprimer mon compte',
            onPressed: widget.onMonCompte,
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Mes compétitions'),
                    selected: _mesCompetitions,
                    onSelected: (_) => setState(() => _mesCompetitions = true),
                  ),
                  ChoiceChip(
                    label: const Text('Inscriptions ouvertes'),
                    selected: !_mesCompetitions,
                    onSelected: (_) => setState(() => _mesCompetitions = false),
                  ),
                ],
              ),
            ),
            if (_competitionsController.chargement)
              const LinearProgressIndicator(),
            if (_competitionsAffichees.isNotEmpty &&
                (_mesCompetitions
                        ? _competitionsController.erreurInscriptions
                        : _competitionsController.erreur) !=
                    null)
              MaterialBanner(
                content: const Text(
                  'Actualisation impossible. Les dernières informations connues restent affichées.',
                ),
                actions: [
                  TextButton(
                    onPressed: _recharger,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            Expanded(child: _construireContenu()),
          ],
        ),
      ),
    );
  }

  Widget _construireContenu() {
    if (_competitionsController.chargement && _competitionsAffichees.isEmpty) {
      return const _ChargementCompetitions();
    }

    if (!_mesCompetitions &&
        _competitionsController.erreur != null &&
        _competitionsAffichees.isEmpty) {
      return _ErreurCompetitions(
        message: _competitionsController.erreur!,
        onReessayer: _recharger,
      );
    }

    if (_mesCompetitions &&
        _competitionsController.erreurInscriptions != null &&
        _competitionsAffichees.isEmpty) {
      return _ErreurCompetitions(
        message: _competitionsController.erreurInscriptions!,
        onReessayer: _recharger,
      );
    }
    if (_competitionsAffichees.isEmpty) {
      if (!_mesCompetitions) return const _AucuneCompetitionOuverte();
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tu n’es inscrit à aucune compétition.'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _mesCompetitions = false),
              child: const Text('Voir les inscriptions ouvertes'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _recharger,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _competitionsAffichees.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final competition = _competitionsAffichees[index];

          final inscription = _inscriptionController.inscriptionUtilisateurPour(
            competition.id,
          );

          return CarteCompetitionAthlete(
            competition: competition,
            etatInscription: _inscriptionController.suiviUtilisateur.pour(
              competition.id,
            ),
            onReessayer: () => _inscriptionController
                .verifierInscriptionUtilisateur(competition: competition),
            inscriptionEnCours: _inscriptionController.inscriptionEnCours,
            desinscriptionEnCours: _inscriptionController.desinscriptionEnCours,
            onInscrire:
                competition.estOuverte && !_competitionsController.chargement
                ? () => _inscrire(competition)
                : null,
            onVoirResultats: inscription != null || _mesCompetitions
                ? () => _ouvrirResultats(competition)
                : null,
            onDesinscrire:
                inscription == null ||
                    !competition.estOuverte ||
                    _competitionsController.chargement
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
                const Text('Tes compétitions et tes résultats'),
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
