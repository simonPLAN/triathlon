abstract interface class SuppressionCompteRepository {
  Future<void> supprimer(String motDePasse);
  Future<void> effacerSessionLocale();
}
