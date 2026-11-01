import '../entities/profil_utilisateur.dart';

abstract interface class ProfilRepository {
  Future<ProfilUtilisateur> obtenirProfilConnecte();
}
