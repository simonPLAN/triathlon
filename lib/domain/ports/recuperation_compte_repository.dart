abstract interface class RecuperationCompteRepository {
  Future<void> envoyerLien(String email, Uri redirection);
  Future<void> verifierLien(Uri lien);
  Future<void> changerMotDePasse(String motDePasse);
  Future<void> terminer();
}
