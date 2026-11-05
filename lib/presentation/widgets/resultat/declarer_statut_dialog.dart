import 'package:flutter/material.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/statut_resultat.dart';

class DeclarationStatutParticipant {
  const DeclarationStatutParticipant(this.athleteId, this.statut, this.motif);
  final String athleteId;
  final StatutResultat statut;
  final String motif;
}

class DeclarerStatutDialog extends StatefulWidget {
  const DeclarerStatutDialog({super.key, required this.participants});
  final List<Inscription> participants;
  @override
  State<DeclarerStatutDialog> createState() => _DeclarerStatutDialogState();
}
class _DeclarerStatutDialogState extends State<DeclarerStatutDialog> {
  final _form = GlobalKey<FormState>();
  final _motif = TextEditingController();
  String? _athleteId;
  StatutResultat _statut = StatutResultat.abandon;
  @override
  void dispose() { _motif.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Abandon ou disqualification'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: _form,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(isExpanded: true,
          decoration: const InputDecoration(labelText: 'Participant'),
          items: widget.participants.map((i) => DropdownMenuItem(value: i.athlete.id,
            child: Text('${i.numeroDossard == null ? '' : 'N°${i.numeroDossard} · '}${i.athlete.nomComplet}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => _athleteId = v,
          validator: (v) => v == null ? 'Choisis un participant.' : null),
        DropdownButtonFormField<StatutResultat>(initialValue: _statut,
          decoration: const InputDecoration(labelText: 'Statut'),
          items: const [
            DropdownMenuItem(value: StatutResultat.abandon, child: Text('Abandon')),
            DropdownMenuItem(value: StatutResultat.disqualifie, child: Text('Disqualification'))],
          onChanged: (v) => _statut = v ?? StatutResultat.abandon),
        TextFormField(controller: _motif, maxLength: 800, minLines: 2, maxLines: 4,
          decoration: const InputDecoration(labelText: 'Motif obligatoire'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Explique la décision.' : null),
        const Text('Aucune place ni aucun point ne sera attribué. Une correction reste possible après la fin de la manche.'),
      ])))),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Retour')),
      FilledButton(onPressed: () {
        if (_form.currentState!.validate()) {
          Navigator.of(context).pop(DeclarationStatutParticipant(_athleteId!, _statut, _motif.text.trim()));
        }
      }, child: const Text('Confirmer le statut')),
    ],
  );
}
