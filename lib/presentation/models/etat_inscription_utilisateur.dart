import '../../domain/entities/inscription.dart';

enum StatutVerificationInscription { nonVerifiee, enCours, verifiee, erreur }

class EtatInscriptionUtilisateur {
  const EtatInscriptionUtilisateur({
    this.statut = StatutVerificationInscription.nonVerifiee,
    this.inscription,
    this.erreur,
  });

  final StatutVerificationInscription statut;
  final Inscription? inscription;
  final String? erreur;
}
