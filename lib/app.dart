import 'package:flutter/material.dart';

import 'presentation/controllers/athlete_controller.dart';
import 'presentation/pages/athletes_page.dart';

class TriathlonApp extends StatelessWidget {
  const TriathlonApp({super.key, required this.athleteController});

  final AthleteController athleteController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Competition sportive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AthletesPage(controller: athleteController),
    );
  }
}
