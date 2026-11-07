import '../entities/edition_resultat.dart';

abstract interface class EditionResultatsRepository {
  /// Renvoie le classement complet issu d'une seule transaction.
  Future<EditionResultats> editer(ModificationResultat modification);
}
