abstract interface class AuthRepository {
  Future<void> inscrireAthlete({
    required String pseudo,
    required String email,
    required String motDePasse,
  });

  Future<void> connecter({required String email, required String motDePasse});

  Future<void> deconnecter();

  bool get estConnecte;
}
