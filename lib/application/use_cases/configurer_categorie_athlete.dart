import '../../domain/ports/categorie_athlete_repository.dart';
import '../../domain/services/coefficients_athletes.dart';

class ConfigurerCategorieAthlete {
  const ConfigurerCategorieAthlete(this.repository);
  final CategorieAthleteRepository repository;
  Future<void> executer(String athleteId, String? categorie) {
    if (athleteId.trim().isEmpty) throw ArgumentError('Athlète obligatoire.');
    if (categorie != null &&
        !CoefficientsAthletes.bareme.containsKey(categorie)) {
      throw ArgumentError('Cette catégorie n’a pas de coefficient défini.');
    }
    return repository.enregistrer(athleteId, categorie);
  }
}
