import '../../domain/ports/auth_repository.dart';

class ConnecterUtilisateur {
  ConnecterUtilisateur(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> executer({
    required String email,
    required String motDePasse,
  }) async {
    final emailNettoye = email.trim().toLowerCase();

    if (emailNettoye.isEmpty || !emailNettoye.contains('@')) {
      throw ArgumentError('Saisis une adresse e-mail valide.');
    }

    if (motDePasse.isEmpty) {
      throw ArgumentError('Le mot de passe est obligatoire.');
    }

    await _authRepository.connecter(
      email: emailNettoye,
      motDePasse: motDePasse,
    );
  }
}
