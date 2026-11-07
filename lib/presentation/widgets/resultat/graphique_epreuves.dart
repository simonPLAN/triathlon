import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ValeurGraphiqueEpreuve {
  const ValeurGraphiqueEpreuve(this.nom, this.valeur, this.description);
  final String nom;
  final double valeur;
  final String description;
}

class GraphiqueEpreuves extends StatelessWidget {
  const GraphiqueEpreuves({
    super.key,
    required this.valeurs,
    required this.unite,
    required this.onSelection,
    this.selection,
  });

  final List<ValeurGraphiqueEpreuve> valeurs;
  final String unite;
  final ValueChanged<int> onSelection;
  final int? selection;

  @override
  Widget build(BuildContext context) {
    if (valeurs.isEmpty) return const SizedBox.shrink();
    final couleurs = Theme.of(context).colorScheme;
    final maximum = valeurs.fold<double>(
      0,
      (precedent, valeur) =>
          valeur.valeur > precedent ? valeur.valeur : precedent,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Touchez une barre ou une épreuve pour voir son détail ($unite).'),
        const SizedBox(height: 16),
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth > valeurs.length * 72.0
                    ? constraints.maxWidth
                    : valeurs.length * 72.0,
                height: 240,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: maximum <= 0 ? 1 : maximum * 1.2,
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(value < 10 ? 1 : 0),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('E${value.toInt() + 1}'),
                          ),
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        final index = response?.spot?.touchedBarGroupIndex;
                        if (event.isInterestedForInteractions &&
                            index != null &&
                            index != selection) {
                          onSelection(index);
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => couleurs.inverseSurface,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final valeur = valeurs[groupIndex];
                          return BarTooltipItem(
                            '${valeur.nom}\n${valeur.description}',
                            TextStyle(color: couleurs.onInverseSurface),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < valeurs.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: valeurs[i].valeur,
                              width: 24,
                              color: selection == i
                                  ? couleurs.secondary
                                  : couleurs.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < valeurs.length; i++)
              ChoiceChip(
                label: Text('E${i + 1} · ${valeurs[i].nom}'),
                selected: selection == i,
                onSelected: (_) => onSelection(i),
              ),
          ],
        ),
      ],
    );
  }
}
