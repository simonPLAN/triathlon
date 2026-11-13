import 'package:flutter/material.dart';

import '../../../application/use_cases/epreuve/gerer_partage_epreuve.dart';
import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/partage_epreuve.dart';

class CoachsAutorisesEpreuvePage extends StatefulWidget {
  const CoachsAutorisesEpreuvePage({
    super.key,
    required this.epreuve,
    required this.partages,
  });

  final Epreuve epreuve;
  final GererPartageEpreuve partages;

  @override
  State<CoachsAutorisesEpreuvePage> createState() =>
      _CoachsAutorisesEpreuvePageState();
}

class _CoachsAutorisesEpreuvePageState
    extends State<CoachsAutorisesEpreuvePage> {
  final _pseudo = TextEditingController();
  List<CoachAutoriseEpreuve> _coachs = const [];
  bool _chargement = true;
  bool _operation = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _pseudo.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final coachs = await widget.partages.listerCoachs(widget.epreuve.id);
      if (mounted) setState(() => _coachs = coachs);
    } catch (erreur) {
      if (mounted) setState(() => _erreur = _message(erreur));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  String _message(Object erreur) => erreur is StateError
      ? erreur.message.toString()
      : erreur is ArgumentError
      ? erreur.message.toString()
      : 'Impossible de gérer les accès. Vérifie ta connexion puis réessaie.';

  Future<void> _autoriser() async {
    if (_operation || _chargement) return;
    setState(() {
      _operation = true;
      _erreur = null;
    });
    try {
      await widget.partages.autoriser(widget.epreuve.id, _pseudo.text);
      if (!mounted) return;
      _pseudo.clear();
      await _charger();
    } catch (erreur) {
      if (mounted) setState(() => _erreur = _message(erreur));
    } finally {
      if (mounted) setState(() => _operation = false);
    }
  }

  Future<void> _retirer(CoachAutoriseEpreuve coach) async {
    if (_operation || _chargement) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet accès ?'),
        content: Text(
          '${coach.pseudo} ne pourra plus consulter cette épreuve ni saisir ses résultats. '
          'Les résultats déjà enregistrés seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer l’accès'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    setState(() {
      _operation = true;
      _erreur = null;
    });
    try {
      await widget.partages.retirer(widget.epreuve.id, coach.id);
      if (mounted) await _charger();
    } catch (erreur) {
      if (mounted) setState(() => _erreur = _message(erreur));
    } finally {
      if (mounted) setState(() => _operation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final occupe = _operation || _chargement;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coachs autorisés'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: occupe ? null : _charger,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.epreuve.nom,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ajoute le pseudo exact d’un coach ayant déjà un compte. '
            'Il pourra consulter les manches, saisir les arrivées et corriger les résultats non publiés. '
            'Tu conserves la configuration, les départs, la validation et la publication.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pseudo,
            enabled: !occupe,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Pseudo du coach',
              prefixIcon: Icon(Icons.person_add_outlined),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _autoriser(),
          ),
          FilledButton.icon(
            onPressed: occupe ? null : _autoriser,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Autoriser ce coach'),
          ),
          if (occupe)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          if (_erreur != null) ...[
            Text(
              _erreur!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: occupe ? null : _charger,
              child: const Text('Réessayer'),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Accès accordés',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!_chargement && _coachs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucun autre coach n’est autorisé pour cette épreuve.',
              ),
            ),
          for (final coach in _coachs)
            Card(
              child: ListTile(
                leading: const Icon(Icons.sports_outlined),
                title: Text(coach.pseudo),
                subtitle: const Text('Consultation et saisie des résultats'),
                trailing: IconButton(
                  tooltip: 'Retirer l’accès de ${coach.pseudo}',
                  onPressed: occupe ? null : () => _retirer(coach),
                  icon: const Icon(Icons.person_remove_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
