import 'package:flutter/material.dart';

import '../services/event_data.dart';

class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  final EventData data = EventData.instance;
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> addParticipant() async {
    final name = controller.text.trim();

    if (name.isEmpty) return;

    final added = await data.addParticipant(name);

    if (!mounted) return;

    if (added) {
      controller.clear();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Participant ajouté')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom vide ou participant déjà présent')),
      );
    }
  }

  Future<void> confirmRemove(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le participant ?'),
          content: Text('Supprimer $name et ses arrivées enregistrées ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await data.removeParticipant(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Nom du participant',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: addParticipant,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: data,
                builder: (context, _) {
                  if (data.participants.isEmpty) {
                    return const Center(
                      child: Text('Aucun participant enregistré'),
                    );
                  }

                  return ListView.builder(
                    itemCount: data.participants.length,
                    itemBuilder: (context, index) {
                      final name = data.participants[index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(name),
                          trailing: IconButton(
                            tooltip: 'Supprimer',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => confirmRemove(name),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
