import '../../../domain/ports/confirmation_email_repository.dart';

class ConfirmerEmail {
  const ConfirmerEmail(this._repository, this.redirection);
  final ConfirmationEmailRepository _repository;
  final Uri redirection;

  bool correspond(Uri lien) =>
      lien.scheme == redirection.scheme &&
      lien.host == redirection.host &&
      lien.path == redirection.path &&
      !lien.hasPort && lien.userInfo.isEmpty;

  Future<void> renvoyer(String email) async {
    final adresse = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(adresse)) {
      throw ArgumentError('Saisis une adresse e-mail valide.');
    }
    await _repository.renvoyer(adresse);
  }

  Future<void> confirmer(Uri lien) async {
    if (!correspond(lien)) {
      throw ArgumentError('Ce lien de confirmation est invalide.');
    }
    if (_repository.possedeSession) {
      throw StateError('Une session est déjà ouverte. Elle est conservée. Déconnecte-toi avant d’utiliser ce lien pour un autre compte.');
    }
    if (lien.queryParameters.containsKey('error') ||
        lien.queryParameters.containsKey('error_code')) {
      throw StateError('Ce lien est expiré ou déjà utilisé. Demande un nouvel e-mail de confirmation.');
    }
    final code = lien.queryParameters['code'];
    if (code == null || code.isEmpty || code.length > 4096) {
      throw StateError('Ce lien est invalide. Demande un nouvel e-mail depuis cette installation de l’application.');
    }
    await _repository.confirmer(code);
  }
}
