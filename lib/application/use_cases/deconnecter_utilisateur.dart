import '../../domain/ports/auth_repository.dart';

class DeconnecterUtilisateur {
  DeconnecterUtilisateur(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> executer() {
    return _authRepository.deconnecter();
  }
}
