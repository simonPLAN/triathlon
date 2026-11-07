import 'package:flutter/material.dart';

import 'resultats_athlete_page.dart';
import 'programme_athlete_page.dart';
import 'detail_competition_athlete_page.dart';

import '../../../application/use_cases/deconnecter_utilisateur.dart';
import '../../../domain/entities/competition.dart';
import '../../../domain/ports/categorie_athlete_repository.dart';
import '../compte/categorie_athlete_page.dart';
import '../compte/informations_application_page.dart';
import '../../widgets/commun/menu_compte_application.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/profil_utilisateur.dart';
import '../../controllers/competitions_ouvertes_controller.dart';
import '../../controllers/inscription_controller.dart';
import '../../widgets/athlete/carte_competition_athlete.dart';
import '../../widgets/athlete/entete_athlete.dart';
import '../../widgets/athlete/contenu_competitions_athlete.dart';
import '../../widgets/athlete/confirmation_inscription_athlete.dart';

class AthleteDashboardPage extends StatefulWidget {
  const AthleteDashboardPage({
    super.key,
    required this.profil,
    this.onMonCompte,
    this.categoriesAthletes,
    required this.competitionsController,
    required this.inscriptionController,
    required this.deconnecterUtilisateur,
  });

  final CategorieAthleteRepository? categoriesAthletes;
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
  bool _confirmationEnCours = false;
  bool _deconnexionEnCours = false;
  bool _mesCompetitions = true;
  List<Competition> get _competitionsAffichees => _mesCompetitions
      ? _competitionsController.inscrites
      : _competitionsController.competitions;

  List<Competition> get _toutesCompetitions => {
    for (final c in _competitionsController.competitions) c.id: c,
    for (final c in _competitionsController.inscrites) c.id: c,
  }.values.toList();

  void _ouvrirDetail(Competition competition) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DetailCompetitionAthletePage(
          competition: competition,
          competitions: _competitionsController,
          inscriptions: _inscriptionController,
          onInscrire: _inscrire,
          onDesinscrire: (c) async {
            final inscription = _inscriptionController
                .inscriptionUtilisateurPour(c.id);
            if (inscription != null) await _desinscrire(c, inscription);
          },
          onProgramme: _ouvrirProgramme,
          onResultats: _ouvrirResultats,
        ),
      ),
    );
  }

  void _ouvrirProgramme(Competition competition) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProgrammeAthletePage(
          competition: competition,
          charger: () =>
              _competitionsController.programmeCompetition(competition.id),
        ),
      ),
    );
  }

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

    final confirmation = await _confirmer(competition, inscrire: false);

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
    if (_deconnexionEnCours) return;
    setState(() => _deconnexionEnCours = true);
    try {
      await widget.deconnecterUtilisateur.executer();
    } catch (exception) {
      if (!mounted) {
        return;
      }

      _afficherErreur('La déconnexion a échoué. Réessaie.');
    } finally {
      if (mounted) setState(() => _deconnexionEnCours = false);
    }
  }

  Future<void> _inscrire(Competition competition) async {
    if (_inscriptionController.inscriptionEnCours) {
      return;
    }

    if (_inscriptionController.estInscritA(competition.id)) {
      return;
    }

    final confirmation = await _confirmer(competition, inscrire: true);

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

  Future<bool> _confirmer(
    Competition competition, {
    required bool inscrire,
  }) async {
    if (_confirmationEnCours) return false;
    _confirmationEnCours = true;
    try {
      return await confirmerInscriptionAthlete(
        context,
        competition,
        inscrire: inscrire,
      );
    } finally {
      _confirmationEnCours = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final erreur = _mesCompetitions
        ? _competitionsController.erreurInscriptions
        : _competitionsController.erreur;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace athlète'),
        actions: [
          IconButton(
            tooltip: 'Informations',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => InformationsApplicationPage(
                  onSupprimerCompte: widget.onMonCompte,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: _competitionsController.chargement ? null : _recharger,
          ),
          MenuCompteApplication(
            operationEnCours: _deconnexionEnCours,
            onDeconnecter: _deconnecter,
            onSupprimerCompte: widget.onMonCompte,
            onCoefficient: widget.categoriesAthletes == null
                ? null
                : () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CategorieAthletePage(
                        repository: widget.categoriesAthletes!,
                        athleteId: widget.profil.id,
                        nomAthlete: widget.profil.nomComplet,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ContenuCompetitionsAthlete(
              competitions: _competitionsAffichees,
              chargement: _competitionsController.chargement,
              mesCompetitions: _mesCompetitions,
              erreur: erreur,
              onRecharger: _recharger,
              onVoirOuvertes: () => setState(() => _mesCompetitions = false),
              construireCarte: _carteCompetition,
              entete: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EnteteAthlete(profil: widget.profil),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Mes compétitions'),
                          selected: _mesCompetitions,
                          onSelected: (_) =>
                              setState(() => _mesCompetitions = true),
                        ),
                        ChoiceChip(
                          label: const Text('Inscriptions ouvertes'),
                          selected: !_mesCompetitions,
                          onSelected: (_) =>
                              setState(() => _mesCompetitions = false),
                        ),
                      ],
                    ),
                  ),
                  if (_competitionsController.chargement)
                    const LinearProgressIndicator(),
                  if (_competitionsAffichees.isNotEmpty && erreur != null)
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _carteCompetition(Competition competition) {
    final inscription = _inscriptionController.inscriptionUtilisateurPour(
      competition.id,
    );
    return CarteCompetitionAthlete(
      competition: competition,
      onVoirDetail: () => _ouvrirDetail(competition),
      onVoirProgramme: () => _ouvrirProgramme(competition),
      etatInscription: _inscriptionController.suiviUtilisateur.pour(
        competition.id,
      ),
      onReessayer: () => _inscriptionController.verifierInscriptionUtilisateur(
        competition: competition,
      ),
      inscriptionEnCours: _inscriptionController.inscriptionEnCours,
      desinscriptionEnCours: _inscriptionController.desinscriptionEnCours,
      onInscrire: competition.estOuverte && !_competitionsController.chargement
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
          : () => _desinscrire(competition, inscription),
    );
  }
}
