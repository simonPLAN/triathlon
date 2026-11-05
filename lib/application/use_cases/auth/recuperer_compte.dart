import '../../../domain/ports/recuperation_compte_repository.dart';
import '../../../domain/services/lien_recuperation.dart';

class RecupererCompte {
  RecupererCompte(this._repository, this.liens);
  final RecuperationCompteRepository _repository;
  final LienRecuperation liens;

  Future<void> envoyerLien(String email) {
    final adresse = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(adresse)) {
      throw ArgumentError('Saisis une adresse e-mail valide.');
    }
    return _repository.envoyerLien(adresse, liens.redirection);
  }

  Future<void> verifierLien(Uri lien) {
    if (!liens.correspond(lien)) {
      throw ArgumentError(
        'Ce lien de récupération ne correspond pas à cette application.',
      );
    }
    return _repository.verifierLien(lien);
  }

  Future<void> changerMotDePasse(String motDePasse, String confirmation) {
    if (motDePasse.length < 8) {
      throw ArgumentError('Utilise au moins 8 caractères.');
    }
    if (motDePasse != confirmation) {
      throw ArgumentError('Les deux mots de passe doivent être identiques.');
    }
    return _repository.changerMotDePasse(motDePasse);
  }

  Future<void> terminer() => _repository.terminer();
}
