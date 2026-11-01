import 'package:flutter/material.dart';

import '../../application/use_cases/deconnecter_utilisateur.dart';
import '../../application/use_cases/inscrire_athlete.dart';
import '../controllers/athlete_controller.dart';

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
  State<AthletesPage> createState() {
    return _AthletesPageState();
  }
}

class _AthletesPageState extends State<AthletesPage> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_rafraichir);
    widget.controller.charger();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rafraichir);
    super.dispose();
  }

  void _rafraichir() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlètes'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await widget.deconnecterUtilisateur.executer();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (controller.chargement && controller.athletes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.erreur != null && controller.athletes.isEmpty) {
            return _ErreurChargement(
              message: controller.erreur!,
              onReessayer: controller.charger,
            );
          }

          if (controller.athletes.isEmpty) {
            return const Center(child: Text('Aucun athlète enregistré.'));
          }

          return RefreshIndicator(
            onRefresh: controller.charger,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.athletes.length,
              separatorBuilder: (_, _) {
                return const Divider();
              },
              itemBuilder: (context, index) {
                final athlete = controller.athletes[index];

                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(athlete.nomComplet),
                  subtitle: Text('Identifiant : ${athlete.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErreurChargement extends StatelessWidget {
  const _ErreurChargement({required this.message, required this.onReessayer});

  final String message;
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
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
