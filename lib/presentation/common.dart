import 'package:flutter/material.dart';

String dateFr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String timeFr(DateTime? d) => d == null
    ? 'Non renseigné'
    : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
void message(BuildContext c, String text, {bool erreur = false}) =>
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: erreur ? Theme.of(c).colorScheme.error : null,
      ),
    );

class Busy extends StatelessWidget {
  const Busy({super.key, this.label = 'Chargement...'});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(label),
      ],
    ),
  );
}
