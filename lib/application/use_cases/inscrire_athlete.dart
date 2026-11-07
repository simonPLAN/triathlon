import '../../domain/ports/auth_repository.dart';

class InscrireAthlete {
  InscrireAthlete(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> executer({
    required String pseudo,
    required String email,
    required String motDePasse,
  }) async {
    final pseudoNettoye = pseudo.trim();
    final emailNettoye = email.trim().toLowerCase();

    if (!RegExp(r'^[A-Za-z0-9_.-]{3,30}$').hasMatch(pseudoNettoye)) {
      throw ArgumentError(
        'Le pseudo doit contenir 3 à 30 lettres, chiffres, points, tirets ou underscores.',
      );
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
      pseudo: pseudoNettoye,
      email: emailNettoye,
      motDePasse: motDePasse,
    );
  }
}
