import '../../domain/entities/athlete.dart';
import '../../domain/ports/athlete_repository.dart';

class AthleteRepositoryMemoire implements AthleteRepository {
  final List<Athlete> _athletes = [
    const Athlete(id: '1', prenom: 'Lea', nom: 'Martin'),
    const Athlete(id: '2', prenom: 'Hugo', nom: 'Bernard'),
  ];

  @override
  Future<void> ajouter(Athlete athlete) async {
    _athletes.add(athlete);
  }

  @override
  Future<List<Athlete>> obtenirTous() async {
    return List.unmodifiable(_athletes);
  }
}
