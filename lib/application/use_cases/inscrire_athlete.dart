import '../../domain/ports/auth_repository.dart';

class InscrireAthlete {
  InscrireAthlete(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> executer({
    required String prenom,
    required String nom,
    required String email,
    required String motDePasse,
  }) async {
    final prenomNettoye = prenom.trim();
    final nomNettoye = nom.trim();
    final emailNettoye = email.trim().toLowerCase();

    if (prenomNettoye.isEmpty) {
      throw ArgumentError('Le prénom est obligatoire.');
    }

    if (nomNettoye.isEmpty) {
      throw ArgumentError('Le nom est obligatoire.');
    }

    if (!emailNettoye.contains('@')) {
      throw ArgumentError('L’adresse e-mail est invalide.');
    }

    if (motDePasse.length < 8) {
      throw ArgumentError(
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
    }

    await _authRepository.inscrireAthlete(
      prenom: prenomNettoye,
      nom: nomNettoye,
      email: emailNettoye,
      motDePasse: motDePasse,
    );
  }
}
