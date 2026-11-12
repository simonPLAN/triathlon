import '../../domain/ports/source_liens_recuperation.dart';

/// Le navigateur recharge l'application à l'ouverture d'un lien Auth.
class LiensRecuperationWeb implements SourceLiensRecuperation {
  @override
  Future<void> demarrer(Future<void> Function(Uri) traiterLien) async {
    await traiterLien(Uri.base);
  }

  @override
  void dispose() {}
}
