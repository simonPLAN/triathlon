abstract interface class AuthRepository {
  Future<void> inscrireAthlete({
    required String prenom,
    required String nom,
    required String email,
    required String motDePasse,
  });

  Future<void> connecter({required String email, required String motDePasse});

  Future<void> deconnecter();

  bool get estConnecte;
}
