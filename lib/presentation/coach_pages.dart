import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../infrastructure/app_repository.dart';
import 'common.dart';
import 'event_pages.dart';

class CoachHome extends StatelessWidget {
  const CoachHome({super.key, required this.repo, required this.profil});
  final AppRepository repo;
  final ProfilUtilisateur profil;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Espace coach'),
      actions: [
        IconButton(onPressed: repo.signOut, icon: const Icon(Icons.logout)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.sports)),
            title: Text('Bonjour ${profil.prenom}'),
            subtitle: const Text('Compte coach'),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          children: [
            _A(
              'Compétitions',
              Icons.emoji_events,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoachCompetitions(repo: repo),
                ),
              ),
            ),
            _A(
              'Athlètes',
              Icons.groups,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TousAthletes(repo: repo)),
              ),
            ),
            _A(
              'Manches',
              Icons.timer,
              () =>
                  message(context, 'Ouvrez une compétition puis une épreuve.'),
            ),
            _A(
              'Résultats',
              Icons.leaderboard,
              () => message(
                context,
                'Ouvrez une manche pour saisir les résultats.',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _A extends StatelessWidget {
  const _A(this.t, this.i, this.tap);
  final String t;
  final IconData i;
  final VoidCallback tap;
  @override
  Widget build(BuildContext c) => Card(
    child: InkWell(
      onTap: tap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(i, size: 42), const SizedBox(height: 8), Text(t)],
      ),
    ),
  );
}

class TousAthletes extends StatelessWidget {
  const TousAthletes({super.key, required this.repo});
  final AppRepository repo;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Athlètes')),
    body: FutureBuilder(
      future: repo.client
          .from('profils')
          .select('id,prenom,nom,role')
          .eq('role', 'athlete')
          .order('nom'),
      builder: (c, s) {
        if (!s.hasData) return const Busy();
        final rows = s.data!;
        if (rows.isEmpty) {
          return const Center(child: Text('Aucun athlète enregistré.'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('${rows[i]['prenom']} ${rows[i]['nom']}'),
            subtitle: Text(rows[i]['id']),
          ),
        );
      },
    ),
  );
}

class CoachCompetitions extends StatefulWidget {
  const CoachCompetitions({super.key, required this.repo});
  final AppRepository repo;
  @override
  State<CoachCompetitions> createState() => _CoachCompetitionsState();
}

class _CoachCompetitionsState extends State<CoachCompetitions> {
  late Future<List<Competition>> f;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => f = widget.repo.competitionsCoach();
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Mes compétitions')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showDialog(
        context: c,
        builder: (_) => CompetitionDialog(repo: widget.repo),
      ).then((_) => setState(reload)),
      icon: const Icon(Icons.add),
      label: const Text('Créer'),
    ),
    body: FutureBuilder(
      future: f,
      builder: (c, s) {
        if (s.hasError) return Center(child: Text('${s.error}'));
        if (!s.hasData) return const Busy();
        if (s.data!.isEmpty) {
          return const Center(child: Text('Aucune compétition.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: s.data!.length,
          itemBuilder: (_, i) {
            final x = s.data![i];
            return Card(
              child: ListTile(
                title: Text(x.nom),
                subtitle: Text(
                  '${dateFr(x.dateCompetition)} • ${x.lieu ?? 'Lieu non renseigné'} • ${x.statut.name}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) =>
                        CompetitionDetail(repo: widget.repo, competition: x),
                  ),
                ).then((_) => setState(reload)),
              ),
            );
          },
        );
      },
    ),
  );
}

class CompetitionDialog extends StatefulWidget {
  const CompetitionDialog({super.key, required this.repo});
  final AppRepository repo;
  @override
  State<CompetitionDialog> createState() => _CompetitionDialogState();
}

class _CompetitionDialogState extends State<CompetitionDialog> {
  final n = TextEditingController(),
      l = TextEditingController(),
      d = TextEditingController();
  DateTime date = DateTime.now().add(const Duration(days: 7));
  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('Nouvelle compétition'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: n,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          TextField(
            controller: l,
            decoration: const InputDecoration(labelText: 'Lieu'),
          ),
          TextField(
            controller: d,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          ListTile(
            title: Text(dateFr(date)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final v = await showDatePicker(
                context: c,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                initialDate: date,
              );
              if (v != null) setState(() => date = v);
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(c),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () async {
          try {
            await widget.repo.creerCompetition(
              nom: n.text,
              date: date,
              lieu: l.text,
              description: d.text,
            );
            if (c.mounted) Navigator.pop(c);
          } catch (e) {
            if (c.mounted) message(c, e.toString(), erreur: true);
          }
        },
        child: const Text('Créer'),
      ),
    ],
  );
}

class CompetitionDetail extends StatefulWidget {
  const CompetitionDetail({
    super.key,
    required this.repo,
    required this.competition,
  });
  final AppRepository repo;
  final Competition competition;
  @override
  State<CompetitionDetail> createState() => _CompetitionDetailState();
}

class _CompetitionDetailState extends State<CompetitionDetail> {
  late Competition c;
  @override
  void initState() {
    super.initState();
    c = widget.competition;
  }

  Future<void> statut(StatutCompetition s) async {
    try {
      c = await widget.repo.changerStatut(c, s);
      setState(() {});
    } catch (e) {
      if (mounted) message(context, e.toString(), erreur: true);
    }
  }

  @override
  Widget build(BuildContext x) => Scaffold(
    appBar: AppBar(
      title: Text(c.nom),
      actions: [
        if (c.estBrouillon)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await widget.repo.supprimerCompetition(c.id);
              if (x.mounted) Navigator.pop(x);
            },
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(c.nom),
            subtitle: Text(
              '${dateFr(c.dateCompetition)} • ${c.lieu ?? ''} • ${c.statut.name}',
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            if (c.estBrouillon)
              FilledButton(
                onPressed: () => statut(StatutCompetition.ouverte),
                child: const Text('Ouvrir les inscriptions'),
              ),
            if (c.statut == StatutCompetition.ouverte)
              FilledButton(
                onPressed: () => statut(StatutCompetition.enCours),
                child: const Text('Démarrer'),
              ),
            if (c.statut == StatutCompetition.enCours)
              FilledButton(
                onPressed: () => statut(StatutCompetition.terminee),
                child: const Text('Terminer'),
              ),
            if (c.statut != StatutCompetition.terminee &&
                c.statut != StatutCompetition.annulee)
              OutlinedButton(
                onPressed: () => statut(StatutCompetition.annulee),
                child: const Text('Annuler'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          children: [
            _A(
              'Athlètes',
              Icons.groups,
              () => Navigator.push(
                x,
                MaterialPageRoute(
                  builder: (_) =>
                      InscriptionsPage(repo: widget.repo, competition: c),
                ),
              ),
            ),
            _A(
              'Épreuves',
              Icons.directions_run,
              () => Navigator.push(
                x,
                MaterialPageRoute(
                  builder: (_) =>
                      EpreuvesPage(repo: widget.repo, competition: c),
                ),
              ),
            ),
            _A(
              'Manches',
              Icons.timer,
              () => message(x, 'Choisissez d’abord une épreuve.'),
            ),
            _A(
              'Résultats',
              Icons.leaderboard,
              () => message(x, 'Choisissez d’abord une manche.'),
            ),
          ],
        ),
      ],
    ),
  );
}
