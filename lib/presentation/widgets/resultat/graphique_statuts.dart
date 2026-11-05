import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphiqueStatuts extends StatefulWidget {
  const GraphiqueStatuts({super.key, required this.repartition});
  final Map<String, int> repartition;

  @override
  State<GraphiqueStatuts> createState() => _GraphiqueStatutsState();
}

class _GraphiqueStatutsState extends State<GraphiqueStatuts> {
  String? _selection;

  static const _libelles = {
    'arrive': 'Arrivés',
    'hors_delai': 'Hors délai',
    'abandon': 'Abandons',
    'disqualifie': 'Disqualifiés',
  };

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final palette = {
      'arrive': couleurs.primary,
      'hors_delai': couleurs.secondary,
      'abandon': couleurs.tertiary,
      'disqualifie': couleurs.error,
    };
    final valeurs = widget.repartition.entries
        .where((e) => e.value > 0)
        .toList();
    final total = valeurs.fold<int>(0, (somme, e) => somme + e.value);
    if (total == 0) return const Text('Aucun résultat pour cette sélection.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Touchez un secteur ou un statut pour afficher sa part.'),
        const SizedBox(height: 12),
        ExcludeSemantics(
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final index = response?.touchedSection?.touchedSectionIndex;
                    if (event.isInterestedForInteractions &&
                        index != null &&
                        index >= 0 &&
                        index < valeurs.length) {
                      setState(() => _selection = valeurs[index].key);
                    }
                  },
                ),
                sections: [
                  for (var i = 0; i < valeurs.length; i++)
                    PieChartSectionData(
                      value: valeurs[i].value.toDouble(),
                      color: palette[valeurs[i].key] ?? couleurs.outline,
                      radius: _selection == valeurs[i].key ? 66 : 56,
                      title: '${(valeurs[i].value * 100 / total).round()} %',
                      titleStyle: TextStyle(
                        color:
                            ThemeData.estimateBrightnessForColor(
                                  palette[valeurs[i].key] ?? couleurs.outline,
                                ) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        for (var i = 0; i < valeurs.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            selected: _selection == valeurs[i].key,
            leading: Icon(
              _selection == valeurs[i].key
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: palette[valeurs[i].key] ?? couleurs.outline,
            ),
            title: Text(_libelles[valeurs[i].key] ?? valeurs[i].key),
            subtitle: Text(
              '${valeurs[i].value} sur $total · '
              '${(valeurs[i].value * 100 / total).toStringAsFixed(1)} %',
            ),
            onTap: () => setState(() => _selection = valeurs[i].key),
          ),
      ],
    );
  }
}
