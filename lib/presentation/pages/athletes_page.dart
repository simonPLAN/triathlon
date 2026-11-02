import 'package:flutter/material.dart';

import '../../application/use_cases/deconnecter_utilisateur.dart';
import '../../application/use_cases/inscrire_athlete.dart';
import '../../domain/entities/athlete.dart';
import '../controllers/athlete_controller.dart';
import '../theme/espacements_application.dart';
import '../widgets/coach/carte_athlete_coach.dart';
import '../widgets/commun/carte_section.dart';
import '../widgets/commun/etat_vide.dart';
import '../widgets/commun/message_erreur.dart';

class AthletesPage extends StatefulWidget {
  const AthletesPage({
    super.key,
    required this.controller,
    required this.inscrireAthlete,
    required this.deconnecterUtilisateur,
  });

  final AthleteController controller;
  final InscrireAthlete inscrireAthlete;
  final DeconnecterUtilisateur deconnecterUtilisateur;

  @override
  State<AthletesPage> createState() => _AthletesPageState();
}

class _AthletesPageState extends State<AthletesPage> {
  final _recherche = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rafraichir);
    widget.controller.charger();
  }

  @override
  void didUpdateWidget(covariant AthletesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rafraichir);
      widget.controller.addListener(_rafraichir);
      widget.controller.charger();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rafraichir);
    _recherche.dispose();
    super.dispose();
  }

  void _rafraichir() {
    if (mounted) setState(() {});
  }

  String _normaliser(String texte) {
    const accents = 'àâäáãåçèéêëìíîïñòóôöõùúûüýÿ';
    const simples = 'aaaaaaceeeeiiiinooooouuuuyy';
    var normalise = texte.toLowerCase().trim();
    for (var i = 0; i < accents.length; i++) {
      normalise = normalise.replaceAll(accents[i], simples[i]);
    }
    return normalise.replaceAll('œ', 'oe').replaceAll('æ', 'ae');
  }

  List<Athlete> get _athletesVisibles {
    final mots = _normaliser(_recherche.text)
        .split(RegExp(r'\s+'))
        .where((mot) => mot.isNotEmpty);
    final athletes = widget.controller.athletes.where((athlete) {
      final nom = _normaliser(athlete.nomComplet);
      return mots.every(nom.contains);
    }).toList();
    athletes.sort((a, b) {
      final comparaison = _normaliser(a.nom).compareTo(_normaliser(b.nom));
      return comparaison != 0
          ? comparaison
          : _normaliser(a.prenom).compareTo(_normaliser(b.prenom));
    });
    return athletes;
  }

  Future<void> _deconnecter() async {
    try {
      await widget.deconnecterUtilisateur.executer();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La déconnexion a échoué. Réessaie.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final athletes = _athletesVisibles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlètes'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.chargement ? null : controller.charger,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: _deconnecter,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EspacementsApplication.largeurContenu,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: CarteSection(
                    titre: 'Répertoire des athlètes',
                    sousTitre: 'Retrouve rapidement un participant par son nom ou son prénom.',
                    icone: Icons.groups_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${controller.athletes.length} athlète(s)',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _recherche,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: 'Rechercher un athlète',
                            hintText: 'Prénom ou nom',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _recherche.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Effacer la recherche',
                                    onPressed: () => setState(_recherche.clear),
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (controller.chargement)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(child: _construireListe(athletes)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construireListe(List<Athlete> athletes) {
    final controller = widget.controller;
    if (controller.chargement && controller.athletes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.erreur != null && controller.athletes.isEmpty) {
      return MessageErreur(
        titre: 'Impossible de charger les athlètes',
        message: controller.erreur!,
        onReessayer: controller.charger,
      );
    }
    if (controller.athletes.isEmpty) {
      return const EtatVide(
        titre: 'Aucun athlète enregistré',
        description:
            'Les athlètes apparaîtront ici après leur inscription. '
            'Pour un invité sans compte, ouvre une compétition puis « Athlètes inscrits ».',
        icone: Icons.groups_outlined,
      );
    }
    if (athletes.isEmpty) {
      return EtatVide(
        titre: 'Aucun athlète trouvé',
        description: 'Essaie un autre nom ou efface la recherche.',
        icone: Icons.person_search_outlined,
        libelleAction: 'Effacer la recherche',
        onAction: () => setState(_recherche.clear),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.charger,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: athletes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _recherche.text.trim().isEmpty
                    ? 'Par ordre alphabétique'
                    : '${athletes.length} résultat(s)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            );
          }
          return CarteAthleteCoach(athlete: athletes[index - 1]);
        },
      ),
    );
  }
}
