import '../../domain/entities/profil_utilisateur.dart';
import '../../domain/ports/profil_repository.dart';

class ObtenirProfilConnecte {
  ObtenirProfilConnecte(this._profilRepository);

  final ProfilRepository _profilRepository;

  Future<ProfilUtilisateur> executer() {
    return _profilRepository.obtenirProfilConnecte();
  }
}
