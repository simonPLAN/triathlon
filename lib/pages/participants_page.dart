import 'package:flutter/material.dart';

import '../constants/sports.dart';
import '../models/participant.dart';
import '../services/event_data.dart';

class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  final EventData data = EventData.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController coefController =
      TextEditingController(text: '1.0');

  @override
  void dispose() {
    nameController.dispose();
    coefController.dispose();
    super.dispose();
  }

  Future<void> addParticipant() async {
    final name = nameController.text.trim();
    final coefText = coefController.text.trim().replaceAll(',', '.');
    final coef = double.tryParse(coefText);

    if (name.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);

    if (coef == null || coef <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppTexts.msgInvalidCoefficient)),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final added = await data.addParticipant(name, coefficient: coef);

    if (!mounted) return;

    if (added) {
      nameController.clear();
      coefController.text = '1.0';

      messenger.showSnackBar(
        const SnackBar(content: Text(AppTexts.msgParticipantAdded)),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppTexts.msgInvalidParticipant)),
      );
    }
  }

  Future<void> editCoefficient(Participant participant) async {
    FocusScope.of(context).unfocus();

    final editController = TextEditingController(
      text: participant.coefficient == participant.coefficient.toInt()
          ? participant.coefficient.toInt().toString()
          : participant.coefficient.toString(),
    );

    final newCoef = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (dialogContextInner, setDialogState) {
            return AlertDialog(
              title: Text(
                '${AppTexts.dialogEditParticipantTitle} (${participant.name})',
              ),
              content: TextField(
                controller: editController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppTexts.labelCoefficient,
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContextInner).pop(),
                  child: const Text(AppTexts.dialogCancel),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(
                      editController.text.trim().replaceAll(',', '.'),
                    );
                    if (parsed != null && parsed > 0) {
                      Navigator.of(dialogContextInner).pop(parsed);
                    } else {
                      setDialogState(() {
                        errorText = AppTexts.msgInvalidCoefficient;
                      });
                    }
                  },
                  child: const Text(AppTexts.dialogSave),
                ),
              ],
            );
          },
        );
      },
    );

    editController.dispose();

    if (newCoef != null && newCoef != participant.coefficient && mounted) {
      await Future.microtask(() {});
      await data.updateParticipant(participant.name, newCoef);
    }
  }

  Future<void> confirmRemove(String name) async {
    FocusScope.of(context).unfocus();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppTexts.dialogRemoveParticipantTitle),
          content: Text(AppTexts.removeParticipantContent(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppTexts.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppTexts.dialogDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await Future.microtask(() {});
      await data.removeParticipant(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppTexts.appBarParticipants)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: AppTexts.labelParticipantName,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: coefController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: AppTexts.labelCoefficient,
                      hintText: AppTexts.labelCoefficientHint,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton.filled(
                    onPressed: addParticipant,
                    icon: const Icon(Icons.add),
                    tooltip: AppTexts.tooltipAdd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: data,
                builder: (context, _) {
                  final participants = data.participantModels;

                  if (participants.isEmpty) {
                    return const Center(
                      child: Text(AppTexts.msgNoParticipants),
                    );
                  }

                  return ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final p = participants[index];

                      return Card(
                        key: ValueKey(p.name),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(p.name),
                          subtitle: Text(
                            AppTexts.participantCoefficientLabel(
                              p.coefficient,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: AppTexts.tooltipEditParticipant,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => editCoefficient(p),
                              ),
                              IconButton(
                                tooltip: AppTexts.tooltipDelete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => confirmRemove(p.name),
                              ),
                            ],
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
