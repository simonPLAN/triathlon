import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/programme_competition.dart';
import '../../controllers/programme_athlete_controller.dart';
import '../../widgets/athlete/carte_epreuve_programme.dart';
import '../../widgets/commun/message_erreur.dart';

class ProgrammeAthletePage extends StatefulWidget {
  const ProgrammeAthletePage({
    super.key,
    required this.competition,
    required this.charger,
  });
  final Competition competition;
  final Future<ProgrammeCompetition> Function() charger;
  @override
  State<ProgrammeAthletePage> createState() => _ProgrammeAthletePageState();
}

class _ProgrammeAthletePageState extends State<ProgrammeAthletePage>
    with WidgetsBindingObserver {
  late final _controller = ProgrammeAthleteController(widget.charger);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_actualiser);
    _controller.recharger();
  }

  void _actualiser() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.recharger();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_actualiser);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Programme'),
      actions: [
        IconButton(
          tooltip: 'Actualiser le programme',
          icon: const Icon(Icons.refresh),
          onPressed: _controller.chargement ? null : _controller.recharger,
        ),
      ],
    ),
    body: SafeArea(child: _contenu()),
  );

  Widget _contenu() {
    if (_controller.chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.erreur != null) {
      return MessageErreur(
        message: _controller.erreur!,
        onReessayer: _controller.recharger,
      );
    }
    final programme = _controller.programme!;
    return RefreshIndicator(
      onRefresh: _controller.recharger,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.competition.nom,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Programme de la compétition, disponible même sans résultats publiés.',
          ),
          if (!programme.affectationsDisponibles) ...[
            const SizedBox(height: 8),
            const Text(
              'Les affectations individuelles et les ordres de départ ne sont pas encore définis.',
            ),
          ],
          const SizedBox(height: 16),
          if (programme.epreuves.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Le coach n’a pas encore défini les épreuves.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final epreuve in programme.epreuves)
            CarteEpreuveProgramme(epreuve: epreuve),
        ],
      ),
    );
  }
}
