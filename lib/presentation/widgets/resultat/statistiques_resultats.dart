import 'package:flutter/material.dart';

import '../../../domain/entities/donnee_statistique.dart';
import '../../../domain/services/calcul_statistiques.dart';
import '../../../domain/services/coefficients_athletes.dart';
import '../commun/carte_section.dart';
import 'graphique_epreuves.dart';
import 'graphique_statuts.dart';

enum _VueStatistique { points, temps, statuts }

class StatistiquesResultats extends StatefulWidget {
  const StatistiquesResultats({
    super.key,
    required this.donnees,
    required this.provenance,
  });
  final List<DonneeStatistique> donnees;
  final String provenance;

  @override
  State<StatistiquesResultats> createState() => _StatistiquesResultatsState();
}

class _StatistiquesResultatsState extends State<StatistiquesResultats> {
  _VueStatistique _vue = _VueStatistique.points;
  String? _epreuveId;
  static const _calcul = CalculStatistiques();

  @override
  Widget build(BuildContext context) {
    final lignes = _calcul.uniques(widget.donnees);
    final epreuves = _calcul.parEpreuve(lignes);
    final selection = epreuves.indexWhere((e) => e.epreuveId == _epreuveId);
    final temps = _vue == _VueStatistique.temps;
    final affichees = temps
        ? epreuves.where((e) => e.moyenneTempsMillisecondes != null).toList()
        : epreuves;
    final selectionGraphique = affichees.indexWhere(
      (e) => e.epreuveId == _epreuveId,
    );
    return CarteSection(
      titre: 'Statistiques',
      sousTitre: widget.provenance,
      icone: Icons.insights_outlined,
      child: lignes.isEmpty
          ? const Text(
              'Les graphiques apparaîtront après les premiers résultats disponibles.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('${lignes.length} résultats')),
                    Chip(
                      label: Text(
                        '${lignes.map((r) => r.athleteId).toSet().length} athlètes',
                      ),
                    ),
                    Chip(label: Text('${epreuves.length} épreuves')),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final vue in _VueStatistique.values)
                      ChoiceChip(
                        label: Text(switch (vue) {
                          _VueStatistique.points => 'Points par épreuve',
                          _VueStatistique.temps => 'Temps par épreuve',
                          _VueStatistique.statuts => 'Statuts',
                        }),
                        selected: _vue == vue,
                        onSelected: (_) => setState(() => _vue = vue),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_vue == _VueStatistique.statuts)
                  GraphiqueStatuts(
                    repartition: _calcul.repartitionStatuts(lignes),
                  )
                else ...[
                  if (temps)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Durées brutes des arrivants uniquement. '
                        'Les temps absents ne valent pas zéro. '
                        'Les distances peuvent différer entre les épreuves.',
                      ),
                    ),
                  if (affichees.isEmpty)
                    const Text(
                      'Aucun temps mesuré disponible pour cette sélection.',
                    )
                  else
                    GraphiqueEpreuves(
                      unite: temps ? 'minutes, moyenne' : 'points cumulés',
                      valeurs: [
                        for (final e in affichees)
                          ValeurGraphiqueEpreuve(
                            e.nomEpreuve,
                            temps
                                ? e.moyenneTempsMillisecondes! / 60000
                                : e.points.toDouble(),
                            temps
                                ? _duree(e.moyenneTempsMillisecondes)
                                : '${e.points} points · ${e.resultats} résultats',
                          ),
                      ],
                      selection: selectionGraphique < 0
                          ? null
                          : selectionGraphique,
                      onSelection: (index) => setState(
                        () => _epreuveId = affichees[index].epreuveId,
                      ),
                    ),
                  if (selection >= 0) ...[
                    const SizedBox(height: 16),
                    _DetailEpreuve(
                      statistique: epreuves[selection],
                      nombreTemps: lignes
                          .where(
                            (r) =>
                                r.epreuveId == _epreuveId &&
                                r.statut == 'arrive' &&
                                r.tempsMillisecondes != null &&
                                r.tempsMillisecondes! >= 0,
                          )
                          .length,
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Données détaillées'),
                  subtitle: const Text(
                    'Version textuelle accessible des graphiques',
                  ),
                  children: [
                    for (final e in epreuves)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.nomEpreuve),
                        subtitle: Text(
                          '${e.resultats} résultats · ${e.arrivees} arrivées\n'
                          'Moyenne : ${_duree(e.moyenneTempsMillisecondes)}',
                        ),
                        trailing: Text('${e.points} pt'),
                        onTap: () => setState(() => _epreuveId = e.epreuveId),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _ouvrirBareme(context),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Comprendre les coefficients'),
                ),
              ],
            ),
    );
  }

  void _ouvrirBareme(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coefficients par catégorie'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Barème fourni par l’organisateur. Une catégorie non renseignée '
                'ou absente de ce barème reste sans coefficient. '
                'Les graphiques affichent les temps bruts ; les coefficients '
                'ne modifient pas automatiquement le classement.',
              ),
              const SizedBox(height: 16),
              for (final entree in CoefficientsAthletes.bareme.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${entree.key} : ${entree.value.toStringAsFixed(4).replaceAll('.', ',')}',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _DetailEpreuve extends StatelessWidget {
  const _DetailEpreuve({required this.statistique, required this.nombreTemps});
  final StatistiquesEpreuve statistique;
  final int nombreTemps;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statistique.nomEpreuve,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${statistique.points} points · ${statistique.resultats} résultats',
              ),
              Text('$nombreTemps temps mesurés'),
              Text(
                'Meilleur : ${_duree(statistique.meilleurTempsMillisecondes)}',
              ),
              Text(
                'Moyenne : ${_duree(statistique.moyenneTempsMillisecondes)}',
              ),
              Text(
                'Médiane : ${_duree(statistique.medianeTempsMillisecondes)}',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _duree(num? millisecondes) {
  if (millisecondes == null) return 'Non disponible';
  final duree = Duration(milliseconds: millisecondes.round());
  final secondes = duree.inSeconds.remainder(60).toString().padLeft(2, '0');
  final milliemes = duree.inMilliseconds
      .remainder(1000)
      .toString()
      .padLeft(3, '0');
  return '${duree.inMinutes}:$secondes.$milliemes';
}
