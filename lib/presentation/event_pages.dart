import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../infrastructure/app_repository.dart';
import 'common.dart';

class InscriptionsPage extends StatefulWidget {
  const InscriptionsPage({
    super.key,
    required this.repo,
    required this.competition,
  });

  final AppRepository repo;
  final Competition competition;

  @override
  State<InscriptionsPage> createState() => _InscriptionsPageState();
}

class _InscriptionsPageState extends State<InscriptionsPage> {
  late Future<List<Inscription>> f;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => f = widget.repo.inscriptions(widget.competition.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Athlètes inscrits')),
      body: FutureBuilder<List<Inscription>>(
        future: f,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Busy();
          final inscriptions = snapshot.data!;
          if (inscriptions.isEmpty) {
            return const Center(child: Text('Aucun athlète inscrit.'));
          }
          return ListView.builder(
            itemCount: inscriptions.length,
            itemBuilder: (context, index) {
              final inscription = inscriptions[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(inscription.numeroDossard?.toString() ?? '-'),
                ),
                title: Text(inscription.athlete.nomComplet),
                subtitle: Text(
                  inscription.numeroDossard == null
                      ? 'Dossard non attribué'
                      : 'Dossard n°${inscription.numeroDossard}',
                ),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'd',
                      child: Text('Attribuer un dossard'),
                    ),
                    PopupMenuItem(value: 'x', child: Text('Désinscrire')),
                  ],
                  onSelected: (value) async {
                    if (value == 'x') {
                      await widget.repo.desinscrire(inscription.id);
                    } else {
                      final ctrl = TextEditingController(
                        text: inscription.numeroDossard?.toString() ?? '',
                      );
                      final numero = await showDialog<int?>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Numéro de dossard'),
                          content: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                int.tryParse(ctrl.text),
                              ),
                              child: const Text('Enregistrer'),
                            ),
                          ],
                        ),
                      );
                      await widget.repo.attribuerDossard(
                        inscription.id,
                        numero,
                      );
                    }
                    setState(load);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _libelleDiscipline(Discipline discipline) {
  switch (discipline) {
    case Discipline.natation:
      return 'Natation';

    case Discipline.velo:
      return 'Vélo';

    case Discipline.courseAPied:
      return 'Course à pied';
  }
}

class EpreuvesPage extends StatefulWidget {
  const EpreuvesPage({
    super.key,
    required this.repo,
    required this.competition,
  });

  final AppRepository repo;
  final Competition competition;

  @override
  State<EpreuvesPage> createState() => _EpreuvesPageState();
}

class _EpreuvesPageState extends State<EpreuvesPage> {
  late Future<List<Epreuve>> f;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => f = widget.repo.epreuves(widget.competition.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Épreuves')),
      floatingActionButton: widget.competition.estBrouillon
          ? FloatingActionButton.extended(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => EpreuveDialog(
                  repo: widget.repo,
                  competition: widget.competition,
                ),
              ).then((_) => setState(load)),
              label: const Text('Créer une épreuve'),
              icon: const Icon(Icons.add),
            )
          : null,
      body: FutureBuilder<List<Epreuve>>(
        future: f,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Busy();
          final epreuves = snapshot.data!;
          if (epreuves.isEmpty) {
            return const Center(child: Text('Aucune épreuve.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: epreuves.length,
            itemBuilder: (context, index) {
              final epreuve = epreuves[index];
              final icon = switch (epreuve.discipline) {
                Discipline.natation => Icons.pool,
                Discipline.velo => Icons.directions_bike,
                _ => Icons.directions_run,
              };
              return Card(
                child: ListTile(
                  leading: Icon(icon),
                  title: Text('${epreuve.ordre}. ${epreuve.nom}'),
                  subtitle: Text(
                    '${epreuve.distanceMetres} m • ${epreuve.nombreManches} manches • délai ${epreuve.dureeLimiteSecondes}s',
                  ),
                  trailing: const Text('Voir les manches →'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManchesPage(
                        repo: widget.repo,
                        competition: widget.competition,
                        epreuve: epreuve,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EpreuveDialog extends StatefulWidget {
  const EpreuveDialog({
    super.key,
    required this.repo,
    required this.competition,
  });

  final AppRepository repo;
  final Competition competition;

  @override
  State<EpreuveDialog> createState() => _EpreuveDialogState();
}

class _EpreuveDialogState extends State<EpreuveDialog> {
  final n = TextEditingController(),
      dist = TextEditingController(),
      nb = TextEditingController(text: '1'),
      delai = TextEditingController(text: '60'),
      ordre = TextEditingController(text: '1');
  Discipline disc = Discipline.natation;

  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('Nouvelle épreuve'),
    content: SingleChildScrollView(
      child: Column(
        children: [
          DropdownButtonFormField<Discipline>(
            initialValue: disc,
            decoration: const InputDecoration(
              labelText: 'Discipline',
              border: OutlineInputBorder(),
            ),
            items: Discipline.values.map((discipline) {
              return DropdownMenuItem<Discipline>(
                value: discipline,
                child: Text(_libelleDiscipline(discipline)),
              );
            }).toList(),
            onChanged: (discipline) {
              if (discipline == null) {
                return;
              }

              setState(() {
                disc = discipline;
              });
            },
          ),
          TextField(
            controller: n,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          TextField(
            controller: dist,
            decoration: const InputDecoration(labelText: 'Distance en mètres'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: nb,
            decoration: const InputDecoration(labelText: 'Nombre de manches'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: ordre,
            decoration: const InputDecoration(labelText: 'Ordre'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: delai,
            decoration: const InputDecoration(labelText: 'Délai en secondes'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () async {
          await widget.repo.creerEpreuve(
            competitionId: widget.competition.id,
            discipline: disc,
            nom: n.text,
            distance: int.parse(dist.text),
            nombreManches: int.parse(nb.text),
            ordre: int.parse(ordre.text),
            delai: int.parse(delai.text),
          );
          if (c.mounted) Navigator.pop(c);
        },
        child: const Text('Créer'),
      ),
    ],
  );
}

class ManchesPage extends StatefulWidget {
  const ManchesPage({
    super.key,
    required this.repo,
    required this.competition,
    required this.epreuve,
  });

  final AppRepository repo;
  final Competition competition;
  final Epreuve epreuve;

  @override
  State<ManchesPage> createState() => _ManchesPageState();
}

class _ManchesPageState extends State<ManchesPage> {
  late Future<List<Manche>> f;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => f = widget.repo.manches(widget.epreuve.id);

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Manches • ${widget.epreuve.nom}')),
    floatingActionButton: widget.competition.estBrouillon
        ? FloatingActionButton.extended(
            onPressed: () async {
              await widget.repo.genererManches(widget.epreuve);
              setState(load);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer'),
          )
        : null,
    body: FutureBuilder(
      future: f,
      builder: (c, s) {
        if (!s.hasData) {
          return const Busy();
        }
        if (s.data!.isEmpty) {
          return const Center(child: Text('Aucune manche générée.'));
        }
        return ListView.builder(
          itemCount: s.data!.length,
          itemBuilder: (_, i) {
            final m = s.data![i];
            return ListTile(
              leading: CircleAvatar(child: Text('${m.numero}')),
              title: Text('Manche ${m.numero}'),
              subtitle: Text(
                '${m.statut.name} • résultats ${m.resultatsPublies ? 'publiés' : 'non publiés'}',
              ),
              onTap: () => Navigator.push(
                c,
                MaterialPageRoute(
                  builder: (_) => MancheDetail(
                    repo: widget.repo,
                    competition: widget.competition,
                    epreuve: widget.epreuve,
                    manche: m,
                  ),
                ),
              ).then((_) => setState(load)),
            );
          },
        );
      },
    ),
  );
}

class MancheDetail extends StatefulWidget {
  const MancheDetail({
    super.key,
    required this.repo,
    required this.competition,
    required this.epreuve,
    required this.manche,
  });

  final AppRepository repo;
  final Competition competition;
  final Epreuve epreuve;
  final Manche manche;

  @override
  State<MancheDetail> createState() => _MancheDetailState();
}

class _MancheDetailState extends State<MancheDetail> {
  late Manche m;

  @override
  void initState() {
    super.initState();
    m = widget.manche;
  }

  Future<void> maj({
    StatutManche? s,
    DateTime? d,
    DateTime? p,
    DateTime? f,
    bool? pub,
  }) async {
    m = await widget.repo.majManche(
      m,
      statut: s,
      depart: d,
      premiere: p,
      fin: f,
      publies: pub,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Manche ${m.numero}')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(widget.epreuve.nom),
            subtitle: Text('Statut : ${m.statut.name}'),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Départ'),
                subtitle: Text(timeFr(m.heureDepart)),
              ),
              ListTile(
                title: const Text('Première arrivée'),
                subtitle: Text(timeFr(m.heurePremiereArrivee)),
              ),
              ListTile(
                title: const Text('Fin du délai'),
                subtitle: Text(timeFr(m.heureFinDelai)),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            if (m.estAVenir)
              FilledButton(
                onPressed: () =>
                    maj(s: StatutManche.enCours, d: DateTime.now()),
                child: const Text('Démarrer'),
              ),
            if (m.estEnCours && m.heurePremiereArrivee == null)
              FilledButton(
                onPressed: () {
                  final now = DateTime.now();
                  maj(
                    p: now,
                    f: now.add(
                      Duration(seconds: widget.epreuve.dureeLimiteSecondes),
                    ),
                  );
                },
                child: const Text('Premier arrivé'),
              ),
            if (m.estEnCours)
              FilledButton(
                onPressed: () => maj(s: StatutManche.terminee),
                child: const Text('Terminer'),
              ),
            if (m.estTerminee && !m.resultatsPublies)
              FilledButton(
                onPressed: () => maj(pub: true),
                child: const Text('Publier'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: m.estEnCours
              ? () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => ResultatsPage(
                      repo: widget.repo,
                      competition: widget.competition,
                      manche: m,
                    ),
                  ),
                )
              : null,
          icon: const Icon(Icons.flag),
          label: const Text('Saisir les arrivées'),
        ),
      ],
    ),
  );
}

class ResultatsPage extends StatefulWidget {
  const ResultatsPage({
    super.key,
    required this.repo,
    required this.competition,
    required this.manche,
  });

  final AppRepository repo;
  final Competition competition;
  final Manche manche;

  @override
  State<ResultatsPage> createState() => _ResultatsPageState();
}

class _ResultatsPageState extends State<ResultatsPage> {
  late Future<List<Resultat>> f;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => f = widget.repo.resultats(widget.manche.id);

  Future<void> add() async {
    final ins = await widget.repo.inscriptions(widget.competition.id);
    final existing = await widget.repo.resultats(widget.manche.id);
    final ids = existing.map((x) => x.athlete.id).toSet();
    final available = ins.where((x) => !ids.contains(x.athlete.id)).toList();
    if (!mounted) return;
    if (available.isEmpty) {
      message(context, 'Tous les athlètes ont déjà un résultat.');
      return;
    }
    final a = await showDialog<ProfilUtilisateur>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Athlète arrivé'),
        children: available
            .map(
              (x) => SimpleDialogOption(
                onPressed: () => Navigator.pop(c, x.athlete),
                child: Text(x.athlete.nomComplet),
              ),
            )
            .toList(),
      ),
    );
    if (a != null) {
      await widget.repo.enregistrerArrivee(manche: widget.manche, athlete: a);
      setState(load);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Résultats')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const Icon(Icons.add),
      label: const Text('Arrivée'),
    ),
    body: FutureBuilder(
      future: f,
      builder: (c, s) {
        if (!s.hasData) return const Busy();
        if (s.data!.isEmpty) {
          return const Center(child: Text('Aucun résultat.'));
        }
        return ListView.builder(
          itemCount: s.data!.length,
          itemBuilder: (_, i) {
            final r = s.data![i];
            return ListTile(
              leading: CircleAvatar(child: Text(r.position?.toString() ?? '-')),
              title: Text(r.athlete.nomComplet),
              subtitle: Text(
                '${r.points} points • ${r.statut.name} • ${timeFr(r.heureArrivee)}',
              ),
            );
          },
        );
      },
    ),
  );
}
