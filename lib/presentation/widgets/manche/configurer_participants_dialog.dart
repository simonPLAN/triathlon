import 'package:flutter/material.dart';

import '../../../domain/entities/groupe_athletes.dart';
import '../../../domain/entities/inscription.dart';
import '../../../domain/entities/manche.dart';

class ConfigurationParticipants {
  const ConfigurationParticipants(this.athleteIds, this.dureeLimiteSecondes);
  final List<String> athleteIds;
  final int dureeLimiteSecondes;
}

class ConfigurerParticipantsDialog extends StatefulWidget {
  const ConfigurerParticipantsDialog({
    super.key,
    required this.manche,
    required this.inscriptions,
    this.groupes = const [],
    required this.dureeParDefaut,
  });

  final Manche manche;
  final List<Inscription> inscriptions;
  final List<GroupeAthletes> groupes;
  final int dureeParDefaut;

  @override
  State<ConfigurerParticipantsDialog> createState() =>
      _ConfigurerParticipantsDialogState();
}

class _ConfigurerParticipantsDialogState
    extends State<ConfigurerParticipantsDialog> {
  late final TextEditingController _delai;
  late List<String> _selection;
  final Set<String> _groupesSelectionnes = {};
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final inscrits = widget.inscriptions.map((i) => i.athlete.id).toSet();
    _selection = widget.manche.participantsAthleteIds
        .where(inscrits.contains)
        .toList();
    _delai = TextEditingController(
      text: '${widget.manche.dureeLimiteSecondes ?? widget.dureeParDefaut}',
    );
  }

  @override
  void dispose() {
    _delai.dispose();
    super.dispose();
  }

  void _deplacer(int origine, int destination) {
    if (destination < 0 || destination >= _selection.length) return;
    setState(() {
      final id = _selection.removeAt(origine);
      _selection.insert(destination, id);
    });
  }

  void _basculerGroupe(GroupeAthletes groupe, bool selectionne) {
    final inscrits = widget.inscriptions.map((i) => i.athlete.id).toSet();
    final membresInscrits = groupe.athleteIds.where(inscrits.contains);
    setState(() {
      if (selectionne) {
        _groupesSelectionnes.add(groupe.id);
        for (final id in membresInscrits) {
          if (!_selection.contains(id)) _selection.add(id);
        }
      } else {
        _groupesSelectionnes.remove(groupe.id);
        final membresAutresGroupes = widget.groupes
            .where((g) => _groupesSelectionnes.contains(g.id))
            .expand((g) => g.athleteIds)
            .toSet();
        _selection.removeWhere(
          (id) =>
              groupe.athleteIds.contains(id) &&
              !membresAutresGroupes.contains(id),
        );
      }
      _erreur = null;
    });
  }

  void _enregistrer() {
    final duree = int.tryParse(_delai.text);
    if (_selection.isEmpty || duree == null || duree < 1 || duree > 86400) {
      setState(
        () => _erreur = 'Sélectionne au moins un athlète et un délai de 1 à 86400 secondes.',
      );
      return;
    }
    Navigator.of(context)
        .pop(ConfigurationParticipants(List.unmodifiable(_selection), duree));
  }

  @override
  Widget build(BuildContext context) {
    final inscrits = {
      for (final inscription in widget.inscriptions)
        inscription.athlete.id: inscription,
    };
    final ids = [
      ..._selection,
      ...inscrits.keys.where((id) => !_selection.contains(id)),
    ];
    final groupesDisponibles = widget.groupes
        .where((groupe) => groupe.athleteIds.any(inscrits.containsKey))
        .toList();

    return AlertDialog(
      title: const Text('Participants et ordre de départ'),
      content: SizedBox(
        width: 560,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              '${_selection.length} sélectionné(s) sur ${inscrits.length} inscrit(s)',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _delai,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Délai après la première arrivée (secondes)',
              ),
            ),
            if (groupesDisponibles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Sélection rapide par groupe',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final groupe in groupesDisponibles)
                    FilterChip(
                      avatar: const Icon(Icons.groups_outlined, size: 18),
                      label: Text(
                        '${groupe.nom} (${groupe.athleteIds.where(inscrits.containsKey).length})',
                      ),
                      selected: _groupesSelectionnes.contains(groupe.id),
                      onSelected: (value) => _basculerGroupe(groupe, value),
                    ),
                ],
              ),
            ],
            Wrap(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selection = inscrits.keys.toList();
                    _groupesSelectionnes.clear();
                  }),
                  child: const Text('Tout sélectionner'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selection = [];
                    _groupesSelectionnes.clear();
                  }),
                  child: const Text('Tout désélectionner'),
                ),
              ],
            ),
            const Text(
              'Les flèches définissent l’ordre de départ, sans modifier les places à l’arrivée.',
            ),
            if (_erreur != null)
              Text(
                _erreur!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (inscrits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucun athlète inscrit. Inscris des participants avant de configurer la manche.',
                ),
              ),
            for (final id in ids) _ligneParticipant(inscrits[id]!, id),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Retour'),
        ),
        FilledButton(
          onPressed: inscrits.isEmpty ? null : _enregistrer,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _ligneParticipant(Inscription inscription, String id) {
    final position = _selection.indexOf(id);
    final dossard = inscription.numeroDossard == null
        ? ''
        : 'N°${inscription.numeroDossard} · ';
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: position >= 0,
      title: Text('$dossard${inscription.athlete.pseudo}'),
      subtitle: position < 0
          ? const Text('Non sélectionné')
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Départ ${position + 1}'),
                IconButton(
                  tooltip: 'Avancer dans l’ordre de départ',
                  onPressed: position > 0
                      ? () => _deplacer(position, position - 1)
                      : null,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Reculer dans l’ordre de départ',
                  onPressed: position < _selection.length - 1
                      ? () => _deplacer(position, position + 1)
                      : null,
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
      onChanged: (value) => setState(() {
        _groupesSelectionnes.clear();
        if (value == true) {
          _selection.add(id);
        } else {
          _selection.remove(id);
        }
      }),
    );
  }
}
