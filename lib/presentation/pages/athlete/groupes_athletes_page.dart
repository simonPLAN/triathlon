import 'package:flutter/material.dart';

import '../../../application/use_cases/athlete/gerer_groupes_athletes.dart';
import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/groupe_athletes.dart';
import '../../widgets/commun/etat_vide.dart';
import '../../widgets/commun/message_erreur.dart';

class GroupesAthletesPage extends StatefulWidget {
  const GroupesAthletesPage({
    super.key,
    required this.gererGroupes,
    required this.athletes,
  });
  final GererGroupesAthletes gererGroupes;
  final List<Athlete> athletes;
  @override
  State<GroupesAthletesPage> createState() => _GroupesAthletesPageState();
}

class _GroupesAthletesPageState extends State<GroupesAthletesPage> {
  List<GroupeAthletes> _groupes = const [];
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final groupes = await widget.gererGroupes.lister();
      if (mounted) setState(() => _groupes = groupes);
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Impossible de charger les groupes.');
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _editer([GroupeAthletes? groupe]) async {
    final saisie = await showDialog<_SaisieGroupe>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupeDialog(groupe: groupe, athletes: widget.athletes),
    );
    if (saisie == null || !mounted) return;
    try {
      await widget.gererGroupes.enregistrer(
        id: groupe?.id,
        nom: saisie.nom,
        athleteIds: saisie.athleteIds,
      );
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupe == null ? 'Groupe créé.' : 'Groupe modifié.'),
          ),
        );
      }
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Future<void> _supprimer(GroupeAthletes groupe) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce groupe ?'),
        content: Text(
          'Le groupe « ${groupe.nom} » sera supprimé. Les athlètes et leurs résultats seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    try {
      await widget.gererGroupes.supprimer(groupe.id);
      await _charger();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La suppression du groupe a échoué.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Groupes d’athlètes'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _chargement ? null : _charger,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: widget.athletes.isEmpty
        ? null
        : FloatingActionButton.extended(
            onPressed: () => _editer(),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Créer un groupe'),
          ),
    body: SafeArea(child: _contenu()),
  );

  Widget _contenu() {
    if (_chargement && _groupes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erreur != null && _groupes.isEmpty) {
      return MessageErreur(
        titre: 'Groupes indisponibles',
        message: _erreur!,
        onReessayer: _charger,
      );
    }
    if (_groupes.isEmpty) {
      return EtatVide(
        titre: 'Aucun groupe',
        description: widget.athletes.isEmpty ? 'Ajoute d’abord des athlètes.' : 'Crée un groupe pour sélectionner plus vite les participants d’une manche.',
        icone: Icons.group_work_outlined,
        libelleAction: widget.athletes.isEmpty ? null : 'Créer un groupe',
        onAction: widget.athletes.isEmpty ? null : () => _editer(),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _groupes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final groupe = _groupes[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
              title: Text(groupe.nom),
              subtitle: Text('${groupe.nombreAthletes} athlète(s)'),
              onTap: () => _editer(groupe),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'modifier') _editer(groupe);
                  if (action == 'supprimer') _supprimer(groupe);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                  PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaisieGroupe {
  const _SaisieGroupe(this.nom, this.athleteIds);
  final String nom;
  final List<String> athleteIds;
}

class _GroupeDialog extends StatefulWidget {
  const _GroupeDialog({required this.groupe, required this.athletes});
  final GroupeAthletes? groupe;
  final List<Athlete> athletes;
  @override
  State<_GroupeDialog> createState() => _GroupeDialogState();
}

class _GroupeDialogState extends State<_GroupeDialog> {
  late final TextEditingController _nom;
  late final Set<String> _selection;

  @override
  void initState() {
    super.initState();
    _nom = TextEditingController(text: widget.groupe?.nom);
    _selection = {...?widget.groupe?.athleteIds};
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  void _valider() {
    final nom = _nom.text.trim();
    if (nom.length < 2 || nom.length > 60 || _selection.isEmpty) return;
    Navigator.pop(
      context,
      _SaisieGroupe(nom, _selection.toList(growable: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final athletes = [
      ...widget.athletes,
    ]..sort((a, b) => a.pseudo.toLowerCase().compareTo(b.pseudo.toLowerCase()));
    return AlertDialog(
      title: Text(
        widget.groupe == null ? 'Créer un groupe' : 'Modifier le groupe',
      ),
      content: SizedBox(
        width: 520,
        child: ListView(
          shrinkWrap: true,
          children: [
            TextField(
              controller: _nom,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nom du groupe'),
              onChanged: (_) => setState(() {}),
            ),
            Text('${_selection.length} athlète(s) sélectionné(s)'),
            const SizedBox(height: 8),
            for (final athlete in athletes)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selection.contains(athlete.id),
                title: Text(athlete.pseudo),
                onChanged: (selectionne) => setState(() {
                  if (selectionne == true) {
                    _selection.add(athlete.id);
                  } else {
                    _selection.remove(athlete.id);
                  }
                }),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _nom.text.trim().length >= 2 && _selection.isNotEmpty
              ? _valider
              : null,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
