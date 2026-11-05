import '../entities/epreuve.dart';

abstract final class ValidationEpreuve {
  static void verifier(Epreuve epreuve) {
    if (epreuve.competitionId.trim().isEmpty) {
      throw ArgumentError('La compétition est obligatoire.');
    }
    if (epreuve.nom.trim().length < 3 || epreuve.nom.trim().length > 100) {
      throw ArgumentError('Le nom doit contenir entre 3 et 100 caractères.');
    }
    if (epreuve.distanceMetres <= 0 ||
        epreuve.distanceMetres > 2147483647 ||
        epreuve.ordre <= 0 ||
        epreuve.ordre > 2147483647 ||
        epreuve.dureeLimiteSecondes <= 0 ||
        epreuve.dureeLimiteSecondes > 2147483647) {
      throw ArgumentError(
        'La distance, l’ordre et le délai doivent être des entiers positifs valides.',
      );
    }
    if (epreuve.nombreManches <= 0 || epreuve.nombreManches > 1000) {
      throw ArgumentError(
        'Le nombre de manches doit être compris entre 1 et 1000.',
      );
    }
  }
}
