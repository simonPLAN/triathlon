import '../../../domain/entities/groupe_athletes.dart';
import '../../../domain/ports/groupe_athletes_repository.dart';

class GererGroupesAthletes {
  const GererGroupesAthletes(this._repository);

  final GroupeAthletesRepository _repository;

  Future<List<GroupeAthletes>> lister() => _repository.lister();

  Future<GroupeAthletes> enregistrer({
    String? id,
    required String nom,
    required List<String> athleteIds,
  }) {
    final nomNettoye = nom.trim();
    if (nomNettoye.length < 2 || nomNettoye.length > 60) {
      throw ArgumentError(
        'Le nom du groupe doit contenir entre 2 et 60 caractères.',
      );
    }
    if (athleteIds.isEmpty) {
      throw ArgumentError('Sélectionne au moins un athlète.');
    }
    return _repository.enregistrer(
      id: id,
      nom: nomNettoye,
      athleteIds: athleteIds.toSet().toList(growable: false),
    );
  }

  Future<void> supprimer(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Le groupe est introuvable.');
    }
    return _repository.supprimer(id);
  }
}
