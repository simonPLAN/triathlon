import 'package:flutter/material.dart';

import '../../../domain/entities/edition_resultat.dart';
import '../../formatters/temps_resultat.dart';

class ChampsClassementResultat extends StatelessWidget {
  const ChampsClassementResultat({
    super.key,
    required this.temps,
    required this.position,
    required this.mode,
    required this.onModeChanged,
    required this.maximum,
    required this.echangeAutorise,
  });
  final TextEditingController temps;
  final TextEditingController position;
  final ModeReclassement mode;
  final ValueChanged<ModeReclassement> onModeChanged;
  final int maximum;
  final bool echangeAutorise;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 12),
      TextFormField(
        key: const ValueKey('temps-manuel'),
        controller: temps,
        keyboardType: TextInputType.datetime,
        decoration: const InputDecoration(
          labelText: 'Temps total',
          hintText: '05:23.450',
          helperText: 'Minutes:secondes.millisecondes (7 jours maximum)',
        ),
        validator: (value) => TempsResultat.lire(value ?? '') == null
            ? 'Utilise le format minutes:secondes.millisecondes.'
            : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<ModeReclassement>(
        key: const ValueKey('mode-reclassement'),
        initialValue: mode,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Reclassement'),
        items: [
          const DropdownMenuItem(
            value: ModeReclassement.temps,
            child: Text('Classer par temps'),
          ),
          const DropdownMenuItem(
            value: ModeReclassement.decaler,
            child: Text('Décaler les autres places'),
          ),
          if (echangeAutorise)
            const DropdownMenuItem(
              value: ModeReclassement.echanger,
              child: Text('Échanger deux places'),
            ),
        ],
        onChanged: (value) {
          if (value != null) onModeChanged(value);
        },
      ),
      if (mode != ModeReclassement.temps) ...[
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('position-corrigee'),
          controller: position,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Position',
            helperText: 'De 1 à $maximum',
          ),
          validator: (value) {
            final place = int.tryParse(value?.trim() ?? '');
            return place == null || place < 1 || place > maximum
                ? 'Saisis une place entre 1 et $maximum.'
                : null;
          },
        ),
        const Text(
          'Les temps des autres athlètes restent inchangés. Un écart négatif indique un temps plus court que celui du premier classé.',
        ),
      ],
    ],
  );
}
