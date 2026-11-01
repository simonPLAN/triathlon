import 'package:flutter/material.dart';

import '../controllers/athlete_controller.dart';

class AthletesPage extends StatefulWidget {
  const AthletesPage({super.key, required this.controller});

  final AthleteController controller;

  @override
  State<AthletesPage> createState() => _AthletesPageState();
}

class _AthletesPageState extends State<AthletesPage> {
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rafraichir);
    widget.controller.charger();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rafraichir);
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  void _rafraichir() {
    if (mounted) setState(() {});
  }

  Future<void> _ouvrirAjout() async {
    _prenomController.clear();
    _nomController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un athlete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _prenomController,
              decoration: const InputDecoration(labelText: 'Prenom'),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final succes = await widget.controller.ajouter(
                prenom: _prenomController.text,
                nom: _nomController.text,
              );
              if (succes && dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Athletes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirAjout,
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
      body: Builder(
        builder: (context) {
          if (controller.chargement && controller.athletes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.erreur != null && controller.athletes.isEmpty) {
            return Center(child: Text(controller.erreur!));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.athletes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final athlete = controller.athletes[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(athlete.nomComplet),
                subtitle: Text('Identifiant : ${athlete.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
