import 'role_utilisateur.dart';

class ProfilUtilisateur {
  const ProfilUtilisateur({
    required this.id,
    String? pseudo,
    this.prenom = '',
    this.nom = '',
    required this.role,
    // Le paramètre public reste `pseudo`, le stockage privé permet la compatibilité.
    // ignore: prefer_initializing_formals
  }) : _pseudo = pseudo;

  final String id;
  final String? _pseudo;

  @Deprecated('Utiliser pseudo')
  final String prenom;

  @Deprecated('Utiliser pseudo')
  final String nom;

  final RoleUtilisateur role;

  String get pseudo {
    final valeur = _pseudo?.trim();
    return valeur == null || valeur.isEmpty ? '$prenom $nom'.trim() : valeur;
  }

  String get nomComplet => pseudo;

  bool get estCoach => role == RoleUtilisateur.coach;

  bool get estAthlete => role == RoleUtilisateur.athlete;
}
