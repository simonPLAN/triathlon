abstract interface class SourceLiensRecuperation {
  Future<void> demarrer(Future<void> Function(Uri) traiterLien);
  void dispose();
}
