import 'package:flutter/material.dart';

import 'app.dart';
import 'application/use_cases/ajouter_athlete.dart';
import 'application/use_cases/lister_athletes.dart';
import 'infrastructure/repositories/athlete_repository_memoire.dart';
import 'presentation/controllers/athlete_controller.dart';

void main() {
  final athleteRepository = AthleteRepositoryMemoire();

  final athleteController = AthleteController(
    ajouterAthlete: AjouterAthlete(athleteRepository),
    listerAthletes: ListerAthletes(athleteRepository),
  );

  runApp(TriathlonApp(athleteController: athleteController));
}
