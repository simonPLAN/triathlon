import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../infrastructure/app_repository.dart';
import 'common.dart';

class AthleteHome extends StatefulWidget {
  const AthleteHome({super.key, required this.repo, required this.profil});
  final AppRepository repo;
  final ProfilUtilisateur profil;
  @override
  State<AthleteHome> createState() => _AthleteHomeState();
}

class _AthleteHomeState extends State<AthleteHome> {
  late Future<List<Competition>> future;
  final Map<String, Inscription?> mine = {};
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = widget.repo.competitionsOuvertes();
    future.then((list) async {
      for (final c in list) {
        mine[c.id] = await widget.repo.monInscription(c.id);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Espace athlète'),
      actions: [
        IconButton(
          onPressed: () {
            setState(load);
          },
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: widget.repo.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: FutureBuilder(
      future: future,
      builder: (c, s) {
        if (!s.hasData) return const Busy();
        if (s.data!.isEmpty)
          return const Center(child: Text('Aucune compétition ouverte.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: s.data!.length,
          itemBuilder: (_, i) {
            final x = s.data![i], ins = mine[x.id];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(x.nom, style: Theme.of(c).textTheme.titleLarge),
                    Text('${dateFr(x.dateCompetition)} • ${x.lieu ?? ''}'),
                    const SizedBox(height: 12),
                    if (ins == null)
                      FilledButton.icon(
                        onPressed: () async {
                          try {
                            mine[x.id] = await widget.repo.inscrire(x.id);
                            setState(() {});
                          } catch (e) {
                            if (c.mounted)
                              message(c, e.toString(), erreur: true);
                          }
                        },
                        icon: const Icon(Icons.how_to_reg),
                        label: const Text('S’inscrire'),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Theme.of(c).colorScheme.primaryContainer,
                            child: Text(
                              'Déjà inscrit • ${ins.numeroDossard == null ? 'Dossard non attribué' : 'Dossard n°${ins.numeroDossard}'}',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              await widget.repo.desinscrire(ins.id);
                              mine[x.id] = null;
                              setState(() {});
                            },
                            child: const Text('Se désinscrire'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
