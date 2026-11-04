import 'package:flutter/material.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/manche.dart';

class ConfigurationParticipants {
  const ConfigurationParticipants(this.athleteIds, this.dureeLimiteSecondes);
  final List<String> athleteIds;
  final int dureeLimiteSecondes;
}

class ConfigurerParticipantsDialog extends StatefulWidget {
  const ConfigurerParticipantsDialog({super.key, required this.manche,
    required this.inscriptions, required this.dureeParDefaut});
  final Manche manche;
  final List<Inscription> inscriptions;
  final int dureeParDefaut;
  @override
  State<ConfigurerParticipantsDialog> createState() => _ConfigurerParticipantsDialogState();
}

class _ConfigurerParticipantsDialogState extends State<ConfigurerParticipantsDialog> {
  late final TextEditingController _delai;
  late List<String> _selection;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final inscrits = widget.inscriptions.map((i) => i.athlete.id).toSet();
    _selection = widget.manche.participantsAthleteIds.where(inscrits.contains).toList();
    _delai = TextEditingController(text: '${widget.manche.dureeLimiteSecondes ?? widget.dureeParDefaut}');
  }
  @override
  void dispose() { _delai.dispose(); super.dispose(); }

  void _deplacer(int origine, int destination) {
    if (destination < 0 || destination >= _selection.length) return;
    setState(() { final id = _selection.removeAt(origine); _selection.insert(destination, id); });
  }
  void _enregistrer() {
    final duree = int.tryParse(_delai.text);
    if (_selection.isEmpty || duree == null || duree < 1 || duree > 86400) {
      setState(() => _erreur = 'Sélectionne au moins un athlète et un délai de 1 à 86400 secondes.');
      return;
    }
    Navigator.of(context).pop(ConfigurationParticipants(List.unmodifiable(_selection), duree));
  }

  @override
  Widget build(BuildContext context) {
    final inscrits = {for (final i in widget.inscriptions) i.athlete.id: i};
    final ids = [..._selection, ...inscrits.keys.where((id) => !_selection.contains(id))];
    return AlertDialog(
      title: const Text('Participants et ordre de départ'),
      content: SizedBox(width: 560,
        child: ListView(shrinkWrap: true, children: [
          Text('${_selection.length} sélectionnés sur ${inscrits.length} inscrits'),
          TextField(controller: _delai, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Délai après la première arrivée (secondes)')),
          Wrap(children: [
            TextButton(onPressed: () => setState(() => _selection = inscrits.keys.toList()),
              child: const Text('Tout sélectionner')),
            TextButton(onPressed: () => setState(() => _selection = []),
              child: const Text('Tout désélectionner')),
          ]),
          const Text('Les flèches définissent l’ordre de départ, sans modifier les places à l’arrivée.'),
          if (_erreur != null) Text(_erreur!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (inscrits.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Aucun athlète inscrit. Inscris des participants avant de configurer la manche.')),
          ...ids.map((id) {
            final inscription = inscrits[id];
            if (inscription == null) return const SizedBox.shrink();
            final position = _selection.indexOf(id);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: position >= 0,
              title: Text('${inscription.numeroDossard == null ? '' : 'N°${inscription.numeroDossard} · '}${inscription.athlete.nomComplet}'),
              subtitle: position < 0 ? const Text('Non sélectionné') : Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('Départ ${position + 1}'),
                IconButton(tooltip: 'Avancer dans l’ordre de départ',
                  onPressed: position > 0 ? () => _deplacer(position, position - 1) : null,
                  icon: const Icon(Icons.arrow_upward)),
                IconButton(tooltip: 'Reculer dans l’ordre de départ',
                  onPressed: position < _selection.length - 1 ? () => _deplacer(position, position + 1) : null,
                  icon: const Icon(Icons.arrow_downward)),
              ]),
              onChanged: (value) => setState(() { if (value == true) { _selection.add(id); } else { _selection.remove(id); } }),
            );
          }),
        ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Retour')),
        FilledButton(onPressed: inscrits.isEmpty ? null : _enregistrer, child: const Text('Enregistrer')),
      ],
    );
  }
}
